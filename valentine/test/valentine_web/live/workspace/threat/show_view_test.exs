defmodule ValentineWeb.WorkspaceLive.Threat.ShowViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  defp create_threat(_) do
    threat = threat_fixture()
    %{threat: threat, workspace_id: threat.workspace_id}
  end

  describe "Show" do
    setup [:create_threat]

    test "displays threat", %{conn: conn, threat: threat} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _show_live, html} =
        live(conn, ~p"/workspaces/#{threat.workspace_id}/threats/#{threat.id}")

      assert html =~ "Edit Threat Statement"
      assert html =~ threat.threat_source
    end
  end
end
