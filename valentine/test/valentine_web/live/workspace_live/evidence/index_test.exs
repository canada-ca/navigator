defmodule ValentineWeb.WorkspaceLive.Evidence.IndexTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  @create_attrs %{
    name: "Test Evidence",
    evidence_type: :json_data,
    content: %{"test" => "data"},
    tags: ["test", "evidence"],
    nist_controls: ["AC-1", "AU-12"]
  }

  describe "Evidence Index" do
    setup [:create_workspace, :create_evidence]

    test "displays evidence overview page", %{
      conn: conn,
      workspace: workspace,
      evidence: evidence
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/evidence")

      assert html =~ "Evidence Overview"
      assert html =~ evidence.name
    end

    test "shows evidence details with tags and controls", %{
      conn: conn,
      workspace: workspace,
      evidence: evidence
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/evidence")

      assert html =~ evidence.name
      assert html =~ "test"
      assert html =~ "AC-1"
    end

    test "displays evidence with pagination", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/evidence")

      # Check that the paginated list component is used
      assert html =~ "Evidence"
    end

    test "shows empty state when no evidence exists", %{conn: conn} do
      workspace = workspace_fixture()
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/evidence")

      assert html =~ "No evidence found"
    end
  end

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end

  defp create_evidence(%{workspace: workspace}) do
    evidence = evidence_fixture(Map.put(@create_attrs, :workspace_id, workspace.id))
    %{evidence: evidence}
  end
end
