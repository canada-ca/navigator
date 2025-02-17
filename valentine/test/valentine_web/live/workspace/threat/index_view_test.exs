defmodule ValentineWeb.WorkspaceLive.Threat.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  defp create_threat(_) do
    threat = threat_fixture()
    %{threat: threat, workspace_id: threat.workspace_id}
  end

  describe "Index" do
    setup [:create_threat]

    test "lists all threats", %{conn: conn, threat: threat} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{threat.workspace_id}/threats")

      assert html =~ "Listing Threats"
      assert html =~ threat.threat_source
    end
  end
end
