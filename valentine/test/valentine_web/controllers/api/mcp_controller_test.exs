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
    conn = post(conn, ~p"/mcp", rpc("initialize", %{}))

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
    conn = post(conn, ~p"/mcp", rpc("tools/list", %{}))

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

    update_workspace = Enum.find(tools, &(&1["name"] == "update_workspace"))
    refute Map.has_key?(get_in(update_workspace, ["inputSchema", "properties"]), "permissions")
  end

  test "list_workspaces only returns the API key workspace", %{
    conn: conn,
    workspace: workspace
  } do
    workspace_fixture(%{owner: "mcp@example.com", name: "Other MCP Workspace"})

    conn =
      post(
        conn,
        ~p"/mcp",
        rpc("tools/call", %{"name" => "list_workspaces", "arguments" => %{}})
      )

    assert [%{"type" => "text", "text" => text}] =
             get_in(json_response(conn, 200), ["result", "content"])

    assert [%{"id" => workspace_id}] = Jason.decode!(text)
    assert workspace_id == workspace.id
  end

  test "update_workspace ignores account fields", %{conn: conn, workspace: workspace} do
    conn =
      post(
        conn,
        ~p"/mcp",
        rpc("tools/call", %{
          "name" => "update_workspace",
          "arguments" => %{
            "name" => "Renamed by MCP",
            "owner" => "attacker@example.com",
            "permissions" => %{"attacker@example.com" => "owner"}
          }
        })
      )

    assert get_in(json_response(conn, 200), ["result", "isError"]) == false

    updated_workspace = Composer.get_workspace!(workspace.id)
    assert updated_workspace.name == "Renamed by MCP"
    assert updated_workspace.owner == "mcp@example.com"
    assert updated_workspace.permissions == %{}
  end

  test "tools/call returns threats for the API key workspace", %{
    conn: conn,
    workspace: workspace
  } do
    threat_fixture(%{workspace_id: workspace.id})

    conn =
      post(
        conn,
        ~p"/mcp",
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
        ~p"/mcp",
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
        ~p"/mcp",
        rpc("tools/call", %{
          "name" => "update_application_information",
          "arguments" => %{"content" => "Application context"}
        })
      )

    body = json_response(conn, 200)
    assert get_in(body, ["result", "isError"]) == false

    conn =
      recycle(conn)
      |> put_req_header("authorization", List.first(get_req_header(conn, "authorization")))
      |> post(
        ~p"/mcp",
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

    body = json_response(conn, 200)
    assert get_in(body, ["result", "isError"]) == false

    assert [%{"type" => "text", "text" => text}] = get_in(body, ["result", "content"])
    dfd = Jason.decode!(text)

    assert get_in(dfd, ["nodes", "app", "position"]) == %{"x" => 0, "y" => 0}
    assert get_in(dfd, ["nodes", "browser", "position"]) == %{"x" => 260, "y" => 0}
    assert get_in(dfd, ["nodes", "app", "data", "linked_threats"]) == []
    assert get_in(dfd, ["nodes", "browser", "data", "linked_threats"]) == []
    assert get_in(dfd, ["edges", "browser_to_app", "data", "linked_threats"]) == []
    assert get_in(dfd, ["edges", "browser_to_app", "data", "type"]) == "edge"

    assert %{
             "code" => "auto_positioned_nodes",
             "node_ids" => auto_positioned_node_ids
           } = Enum.find(dfd["validation_hints"], &(&1["code"] == "auto_positioned_nodes"))

    assert Enum.sort(auto_positioned_node_ids) == ["app", "browser"]

    conn =
      recycle(conn)
      |> put_req_header("authorization", List.first(get_req_header(conn, "authorization")))
      |> post(
        ~p"/mcp",
        rpc("tools/call", %{"name" => "export_dfd_mermaid", "arguments" => %{}})
      )

    assert [%{"type" => "text", "text" => mermaid}] =
             get_in(json_response(conn, 200), ["result", "content"])

    assert mermaid =~ "stateDiagram-v2"
    assert mermaid =~ "browser : Browser"
    assert mermaid =~ "browser --> app : HTTPS"
  end

  test "returns DFD usability hints for orphan trust boundaries", %{conn: conn} do
    conn =
      post(
        conn,
        ~p"/mcp",
        rpc("tools/call", %{
          "name" => "update_data_flow_diagram",
          "arguments" => %{
            "nodes" => %{
              "public_boundary" => %{
                "data" => %{
                  "id" => "public_boundary",
                  "label" => "Public Edge Boundary",
                  "type" => "trust_boundary"
                }
              },
              "browser" => %{
                "data" => %{
                  "id" => "browser",
                  "label" => "Browser",
                  "type" => "actor"
                }
              }
            },
            "edges" => %{}
          }
        })
      )

    body = json_response(conn, 200)
    assert get_in(body, ["result", "isError"]) == false

    assert [%{"type" => "text", "text" => text}] = get_in(body, ["result", "content"])
    dfd = Jason.decode!(text)

    assert %{
             "code" => "orphan_trust_boundaries",
             "node_ids" => ["public_boundary"]
           } = Enum.find(dfd["validation_hints"], &(&1["code"] == "orphan_trust_boundaries"))
  end

  test "rejects malformed DFD payloads", %{conn: conn} do
    conn =
      post(
        conn,
        ~p"/mcp",
        rpc("tools/call", %{
          "name" => "update_data_flow_diagram",
          "arguments" => %{
            "nodes" => %{
              "browser" => %{
                "data" => %{
                  "id" => "browser",
                  "label" => "Browser",
                  "type" => "external_system"
                }
              }
            },
            "edges" => %{}
          }
        })
      )

    body = json_response(conn, 200)
    assert get_in(body, ["result", "isError"]) == true
    assert [%{"text" => text}] = get_in(body, ["result", "content"])
    assert text =~ "unsupported data.type"
  end

  test "links entities in the API key workspace", %{conn: conn, workspace: workspace} do
    threat = threat_fixture(%{workspace_id: workspace.id})
    assumption = assumption_fixture(%{workspace_id: workspace.id})

    conn =
      post(
        conn,
        ~p"/mcp",
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
        ~p"/mcp",
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
        ~p"/mcp",
        rpc("tools/call", %{"name" => "missing_tool", "arguments" => %{}})
      )

    assert %{"error" => %{"code" => -32602, "message" => "Unknown tool: missing_tool"}} =
             json_response(conn, 200)
  end

  test "missing required tool arguments return a tool error", %{conn: conn} do
    conn =
      post(
        conn,
        ~p"/mcp",
        rpc("tools/call", %{
          "name" => "update_threat",
          "arguments" => %{"threat_source" => "after"}
        })
      )

    body = json_response(conn, 200)
    assert get_in(body, ["result", "isError"]) == true
    assert [%{"text" => text}] = get_in(body, ["result", "content"])
    assert text == "Missing required arguments: id"
  end

  test "notifications return 202 with no body", %{conn: conn} do
    conn = post(conn, ~p"/mcp", %{"jsonrpc" => "2.0", "method" => "notifications/initialized"})

    assert response(conn, 202) == ""
  end

  test "batch requests return a response array", %{api_key: api_key} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key.key}")
      |> put_req_header("content-type", "application/json")
      |> post(~p"/mcp", Jason.encode!([rpc("initialize", %{}), rpc("tools/list", %{}, 2)]))

    assert [%{"id" => 1}, %{"id" => 2}] = json_response(conn, 200)
  end

  test "GET /mcp returns 405 when authenticated", %{conn: conn} do
    conn = get(conn, ~p"/mcp")

    assert response(conn, 405) == ""
  end

  test "unauthenticated requests return 401" do
    conn = post(build_conn(), ~p"/mcp", rpc("initialize", %{}))

    assert json_response(conn, 401)
  end

  defp rpc(method, params, id \\ 1) do
    %{"jsonrpc" => "2.0", "id" => id, "method" => method, "params" => params}
  end
end
