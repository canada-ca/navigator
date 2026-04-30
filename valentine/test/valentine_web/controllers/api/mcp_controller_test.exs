defmodule ValentineWeb.Api.MCPControllerTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  alias Valentine.Composer

  setup do
    workspace = workspace_fixture(%{name: "MCP Workspace", owner: "mcp@example.com"})
    api_key = api_key_fixture(%{workspace_id: workspace.id, owner: "mcp@example.com"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key.key}")

    %{conn: conn, workspace: workspace, api_key: api_key}
  end

  test "initialize returns server capabilities", %{conn: conn} do
    conn = post(conn, ~p"/api/mcp", rpc("initialize", %{}))

    assert %{
             "jsonrpc" => "2.0",
             "id" => 1,
             "result" => %{
               "protocolVersion" => "2025-03-26",
               "serverInfo" => %{"name" => "navigator"},
               "capabilities" => %{"tools" => %{"listChanged" => false}}
             }
           } = json_response(conn, 200)
  end

  test "tools/list returns the phase 1 tools", %{conn: conn} do
    conn = post(conn, ~p"/api/mcp", rpc("tools/list", %{}))

    tools = get_in(json_response(conn, 200), ["result", "tools"])
    tool_names = Enum.map(tools, & &1["name"])

    assert length(tools) == 25
    assert "list_workspaces" in tool_names
    refute "create_workspace" in tool_names
    assert "create_threat" in tool_names
    assert "export_dfd_mermaid" in tool_names

    create_threat = Enum.find(tools, &(&1["name"] == "create_threat"))
    assert get_in(create_threat, ["annotations", "readOnlyHint"]) == false
    assert get_in(create_threat, ["annotations", "destructiveHint"]) == false

    assert get_in(create_threat, [
             "inputSchema",
             "properties",
             "threat_source",
             "description"
           ]) =~ "Do not include a leading article"

    update_dfd = Enum.find(tools, &(&1["name"] == "update_data_flow_diagram"))

    assert get_in(update_dfd, [
             "inputSchema",
             "properties",
             "nodes",
             "additionalProperties",
             "properties",
             "data",
             "properties",
             "type",
             "enum"
           ]) == ["actor", "process", "datastore", "trust_boundary"]
  end

  test "tools/call returns threats for the API key workspace", %{
    conn: conn,
    workspace: workspace
  } do
    threat_fixture(%{workspace_id: workspace.id})

    conn =
      post(
        conn,
        ~p"/api/mcp",
        rpc("tools/call", %{"name" => "list_threats", "arguments" => %{}})
      )

    body = json_response(conn, 200)
    assert get_in(body, ["result", "isError"]) == false
    assert [%{"type" => "text", "text" => text}] = get_in(body, ["result", "content"])
    assert [%{"workspace_id" => workspace_id}] = Jason.decode!(text)
    assert workspace_id == workspace.id
  end

  test "exports the current workspace as JSON content", %{conn: conn, workspace: workspace} do
    conn =
      post(
        conn,
        ~p"/api/mcp",
        rpc("tools/call", %{"name" => "export_workspace", "arguments" => %{}})
      )

    assert [%{"type" => "text", "text" => text}] =
             get_in(json_response(conn, 200), ["result", "content"])

    expected_name = workspace.name
    assert %{"workspace" => %{"name" => ^expected_name}} = Jason.decode!(text)
  end

  test "supports document and DFD tool calls", %{conn: conn} do
    conn =
      post(
        conn,
        ~p"/api/mcp",
        rpc("tools/call", %{
          "name" => "update_application_information",
          "arguments" => %{"content" => "Application context"}
        })
      )

    assert get_in(json_response(conn, 200), ["result", "isError"]) == false

    conn =
      recycle(conn)
      |> put_req_header("authorization", List.first(get_req_header(conn, "authorization")))
      |> post(
        ~p"/api/mcp",
        rpc("tools/call", %{
          "name" => "update_data_flow_diagram",
          "arguments" => %{
            "nodes" => %{
              "browser" => %{
                "data" => %{
                  "id" => "browser",
                  "label" => "Browser",
                  "type" => "actor"
                }
              },
              "app" => %{
                "data" => %{
                  "id" => "app",
                  "label" => "Phoenix App",
                  "type" => "process"
                }
              }
            },
            "edges" => %{
              "browser_to_app" => %{
                "data" => %{
                  "id" => "browser_to_app",
                  "source" => "browser",
                  "target" => "app",
                  "label" => "HTTPS"
                }
              }
            }
          }
        })
      )

    assert get_in(json_response(conn, 200), ["result", "isError"]) == false

    conn =
      recycle(conn)
      |> put_req_header("authorization", List.first(get_req_header(conn, "authorization")))
      |> post(
        ~p"/api/mcp",
        rpc("tools/call", %{"name" => "export_dfd_mermaid", "arguments" => %{}})
      )

    assert [%{"type" => "text", "text" => mermaid}] =
             get_in(json_response(conn, 200), ["result", "content"])

    assert mermaid =~ "stateDiagram-v2"
    assert mermaid =~ "browser : Browser"
    assert mermaid =~ "browser --> app : HTTPS"
  end

  test "links entities in the API key workspace", %{conn: conn, workspace: workspace} do
    threat = threat_fixture(%{workspace_id: workspace.id})
    assumption = assumption_fixture(%{workspace_id: workspace.id})

    conn =
      post(
        conn,
        ~p"/api/mcp",
        rpc("tools/call", %{
          "name" => "link_entities",
          "arguments" => %{
            "from_type" => "threat",
            "from_id" => threat.id,
            "to_type" => "assumption",
            "to_id" => assumption.id
          }
        })
      )

    assert get_in(json_response(conn, 200), ["result", "isError"]) == false
    linked = Composer.get_threat!(threat.id, [:assumptions])
    assert Enum.map(linked.assumptions, & &1.id) == [assumption.id]
  end

  test "rejects cross-workspace updates", %{conn: conn} do
    other_workspace = workspace_fixture(%{owner: "other@example.com"})
    other_threat = threat_fixture(%{workspace_id: other_workspace.id, threat_source: "before"})

    conn =
      post(
        conn,
        ~p"/api/mcp",
        rpc("tools/call", %{
          "name" => "update_threat",
          "arguments" => %{"id" => other_threat.id, "threat_source" => "after"}
        })
      )

    assert get_in(json_response(conn, 200), ["result", "isError"]) == true
    assert Composer.get_threat!(other_threat.id).threat_source == "before"
  end

  test "unknown tool returns a JSON-RPC protocol error", %{conn: conn} do
    conn =
      post(
        conn,
        ~p"/api/mcp",
        rpc("tools/call", %{"name" => "missing_tool", "arguments" => %{}})
      )

    assert %{"error" => %{"code" => -32602, "message" => "Unknown tool: missing_tool"}} =
             json_response(conn, 200)
  end

  test "notifications return 202 with no body", %{conn: conn} do
    conn =
      post(conn, ~p"/api/mcp", %{"jsonrpc" => "2.0", "method" => "notifications/initialized"})

    assert response(conn, 202) == ""
  end

  test "batch requests return a response array", %{api_key: api_key} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key.key}")
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/mcp", Jason.encode!([rpc("initialize", %{}), rpc("tools/list", %{}, 2)]))

    assert [%{"id" => 1}, %{"id" => 2}] = json_response(conn, 200)
  end

  test "GET /api/mcp returns 405 when authenticated", %{conn: conn} do
    conn = get(conn, ~p"/api/mcp")

    assert response(conn, 405) == ""
  end

  test "unauthenticated requests return 401" do
    conn = post(build_conn(), ~p"/api/mcp", rpc("initialize", %{}))

    assert json_response(conn, 401)
  end

  defp rpc(method, params, id \\ 1) do
    %{"jsonrpc" => "2.0", "id" => id, "method" => method, "params" => params}
  end
end
