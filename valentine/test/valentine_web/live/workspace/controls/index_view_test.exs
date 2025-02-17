defmodule ValentineWeb.WorkspaceLive.Controls.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  setup do
    control = control_fixture()
    workspace = workspace_fixture()

    %{
      control: control,
      workspace_id: workspace.id
    }
  end

  describe "Index" do
    test "lists all controls", %{
      conn: conn,
      control: control,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/controls"
        )

      assert html =~ "NIST Controls"
      assert html =~ control.name
      assert html =~ control.nist_id
    end
  end
end
