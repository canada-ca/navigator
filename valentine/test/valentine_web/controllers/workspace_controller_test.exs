defmodule ValentineWeb.WorkspaceControllerTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  test "GET /workspaces/:workspace_id/export returns a JSON export of the workspace for download",
       %{conn: conn} do
    workspace = workspace_fixture()

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      |> get(~p"/workspaces/#{workspace.id}/export")

    assert conn.status == 200

    assert List.keyfind(conn.resp_headers, "content-disposition", 0) ==
             {"content-disposition",
              "attachment; filename=\"Workspace_some%20name.json\"; filename*=utf-8''Workspace_some%20name.json"}

    assert List.keyfind(conn.resp_headers, "content-type", 0) ==
             {"content-type", "application/json"}

    json = Jason.decode!(conn.resp_body)

    assert json["workspace"]["name"] == workspace.name
  end

  test "GET /workspaces/:workspace_id/export/assumptions returns a JSON export of the workspace assumptions for download",
       %{conn: conn} do
    workspace = workspace_fixture()

    assumption = assumption_fixture(%{workspace_id: workspace.id})

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      |> get(~p"/workspaces/#{workspace.id}/export/assumptions")

    assert conn.status == 200

    assert List.keyfind(conn.resp_headers, "content-disposition", 0) ==
             {"content-disposition",
              "attachment; filename=\"Assumptions_some%20name_Reference_Pack.json\"; filename*=utf-8''Assumptions_some%20name_Reference_Pack.json"}

    assert List.keyfind(conn.resp_headers, "content-type", 0) ==
             {"content-type", "application/json"}

    json = Jason.decode!(conn.resp_body)

    assert json["name"] == workspace.name
    assert json["description"] == "Assumptions for #{workspace.name}"

    assert json["assumptions"] == [
             %{
               "id" => assumption.id,
               "comments" => assumption.comments,
               "content" => assumption.content,
               "tags" => assumption.tags
             }
           ]
  end

  test "GET /workspaces/:workspace_id/export/mitigations returns a JSON export of the workspace mitigations for download",
       %{conn: conn} do
    workspace = workspace_fixture()

    mitigation = mitigation_fixture(%{workspace_id: workspace.id})

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      |> get(~p"/workspaces/#{workspace.id}/export/mitigations")

    assert conn.status == 200

    assert List.keyfind(conn.resp_headers, "content-disposition", 0) ==
             {"content-disposition",
              "attachment; filename=\"Mitigations_some%20name_Reference_Pack.json\"; filename*=utf-8''Mitigations_some%20name_Reference_Pack.json"}

    assert List.keyfind(conn.resp_headers, "content-type", 0) ==
             {"content-type", "application/json"}

    json = Jason.decode!(conn.resp_body)

    assert json["name"] == workspace.name
    assert json["description"] == "Mitigations for #{workspace.name}"

    assert json["mitigations"] == [
             %{
               "id" => mitigation.id,
               "comments" => mitigation.comments,
               "content" => mitigation.content,
               "status" => Atom.to_string(mitigation.status),
               "tags" => mitigation.tags
             }
           ]
  end

  test "GET /workspaces/:workspace_id/export/threats returns a JSON export of the workspace threats for download",
       %{conn: conn} do
    workspace = workspace_fixture()

    threat = threat_fixture(%{workspace_id: workspace.id})

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      |> get(~p"/workspaces/#{workspace.id}/export/threats")

    assert conn.status == 200

    assert List.keyfind(conn.resp_headers, "content-disposition", 0) ==
             {"content-disposition",
              "attachment; filename=\"Threats_some%20name_Reference_Pack.json\"; filename*=utf-8''Threats_some%20name_Reference_Pack.json"}

    assert List.keyfind(conn.resp_headers, "content-type", 0) ==
             {"content-type", "application/json"}

    json = Jason.decode!(conn.resp_body)

    assert json["name"] == workspace.name
    assert json["description"] == "Threats for #{workspace.name}"

    assert json["threats"] == [
             %{
               "id" => threat.id,
               "comments" => threat.comments,
               "impacted_assets" => threat.impacted_assets,
               "impacted_goal" => threat.impacted_goal,
               "prerequisites" => threat.prerequisites,
               "priority" => Atom.to_string(threat.priority),
               "status" => Atom.to_string(threat.status),
               "stride" => ["spoofing"],
               "tags" => threat.tags,
               "threat_action" => threat.threat_action,
               "threat_impact" => threat.threat_impact,
               "threat_source" => threat.threat_source
             }
           ]
  end

  test "GET /workspaces/:workspace_id/data_flow/mermaid returns a Mermaid.js export of the data flow diagram for download",
       %{conn: conn} do
    workspace = workspace_fixture()

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      |> get(~p"/workspaces/#{workspace.id}/data_flow/mermaid")

    assert conn.status == 200

    assert List.keyfind(conn.resp_headers, "content-disposition", 0) ==
             {"content-disposition",
              "attachment; filename=\"DFD_some%20name.mmd\"; filename*=utf-8''DFD_some%20name.mmd"}

    assert List.keyfind(conn.resp_headers, "content-type", 0) ==
             {"content-type", "text/plain"}

    # The response should be a valid Mermaid state diagram
    assert String.starts_with?(conn.resp_body, "stateDiagram-v2")
  end
end
