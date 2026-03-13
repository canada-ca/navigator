defmodule ValentineWeb.WorkspaceLive.ThreatModel.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end

  describe "Index" do
    setup [:create_workspace]

    test "displays the threat model", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _index_live, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/threat_model")

      assert html =~ "Threat model for: #{workspace.name}"
      assert html =~ "Print / Save as PDF"
      assert html =~ "Use your browser"
      assert html =~ "save it as a PDF"
      assert html =~ "Download Markdown"
      assert html =~ "Application Information"
      assert html =~ "Architecture"
      assert html =~ "Data Flow"
      assert html =~ "Mitigations"
      assert html =~ "Threats"
      assert html =~ "Assumptions"
      assert html =~ "data-auto-print=\"false\""
    end

    test "enables auto print when requested", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _index_live, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/threat_model?print=true")

      assert html =~ "data-auto-print=\"true\""
    end
  end
end
