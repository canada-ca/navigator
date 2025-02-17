defmodule ValentineWeb.WorkspaceLive.ShowViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  defp create_workspace(_) do
    workspace = workspace_fixture()
    threat = threat_fixture()
    mitigation = mitigation_fixture()
    %{mitigation: mitigation, threat: threat, workspace: workspace}
  end

  describe "Show" do
    setup [:create_workspace]

    test "display workspace name", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Show Workspace"
      assert html =~ workspace.name
    end

    test "display workspace cloud profile", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Profile"
      assert html =~ workspace.cloud_profile
    end

    test "display workspace cloud profile type", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Type"
      assert html =~ workspace.cloud_profile_type
    end

    test "display mitigation status", %{conn: conn, mitigation: mitigation} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{mitigation.workspace_id}")

      assert html =~ "Mitigation status"
      assert html =~ "[&quot;Identified&quot;]"
    end

    test "display threat prioritization", %{conn: conn, threat: threat} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{threat.workspace_id}")

      assert html =~ "Threats prioritization"
      assert html =~ "[&quot;High&quot;]"
    end

    test "display threat stride", %{conn: conn, threat: threat} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{threat.workspace_id}")

      assert html =~ "Threat STRIDE"
      assert html =~ "Spoofing"
    end
  end
end
