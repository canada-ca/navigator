defmodule ValentineWeb.Api.WorkspaceControllerTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  test "GET /api/workspace returns the workspace data", %{conn: conn} do
    workspace = workspace_fixture(%{name: "Test Workspace", owner: "test_owner"})
    api_key = api_key_fixture(%{workspace_id: workspace.id, owner: "test_owner"})
    conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

    conn = get(conn, ~p"/api/workspace")

    assert json_response(conn, 200) == %{
             "workspace" => %{
               "id" => api_key.workspace_id,
               "name" => workspace.name,
               "owner" => api_key.owner,
               "cloud_profile" => workspace.cloud_profile,
               "cloud_profile_type" => workspace.cloud_profile_type,
               "permissions" => workspace.permissions,
               "url" => workspace.url
             }
           }

    assert conn.assigns[:api_key].id == api_key.id
  end
end
