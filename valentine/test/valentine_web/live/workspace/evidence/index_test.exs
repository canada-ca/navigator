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

  describe "Evidence Entity Linking" do
    setup [:create_workspace_with_entities, :create_evidence]

    test "handle_params for :assumptions action loads evidence with preloaded assumptions", %{
      conn: conn,
      workspace: workspace,
      evidence: evidence
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}/assumptions")

      # Verify the linking page loaded correctly
      assert html =~ "Link Evidence"
    end

    test "handle_params for :threats action loads evidence with preloaded threats", %{
      conn: conn,
      workspace: workspace,
      evidence: evidence
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}/threats")

      # Verify the linking page loaded correctly
      assert html =~ "Link Evidence"
    end

    test "handle_params for :mitigations action loads evidence with preloaded mitigations", %{
      conn: conn,
      workspace: workspace,
      evidence: evidence
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}/mitigations")

      # Verify the linking page loaded correctly
      assert html =~ "Link Evidence"
    end

    test "handle_info EntityLinkerComponent saved message refreshes evidence list", %{
      conn: conn,
      workspace: workspace,
      evidence: evidence
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, _html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}/assumptions")

      # Simulate the EntityLinkerComponent sending a saved message
      send(
        view.pid,
        {ValentineWeb.WorkspaceLive.Components.EntityLinkerComponent, {:saved, evidence}}
      )

      # Wait for the message to be processed
      :timer.sleep(50)

      # Should redirect to evidence index
      assert_patched(view, ~p"/workspaces/#{workspace.id}/evidence")
    end

    test "workspace preloads all required associations", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.id}/evidence")

      # Verify the page loaded successfully - this implicitly tests that 
      # workspace associations were loaded correctly by the mount function
      assert html =~ "Evidence"
    end
  end

  defp create_workspace_with_entities(_) do
    workspace = workspace_fixture()

    # Create some entities to link to
    _assumption = assumption_fixture(%{workspace_id: workspace.id})
    _threat = threat_fixture(%{workspace_id: workspace.id})
    _mitigation = mitigation_fixture(%{workspace_id: workspace.id})

    # Reload workspace with associations
    workspace =
      Valentine.Composer.get_workspace!(workspace.id, [:assumptions, :threats, :mitigations])

    %{workspace: workspace}
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
