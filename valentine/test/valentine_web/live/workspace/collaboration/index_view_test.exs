defmodule ValentineWeb.WorkspaceLive.Collaboration.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  setup do
    user = user_fixture()
    workspace = workspace_fixture(%{owner: user.email})
    some_user = user_fixture(%{email: "some.other.user@localhost"})

    %{
      workspace_id: workspace.id,
      user: user,
      some_user: some_user
    }
  end

  describe "Index" do
    test "lists all users", %{
      conn: conn,
      workspace_id: workspace_id,
      user: user
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: user.email})

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/collaboration"
        )

      assert html =~ "Collaboration"
    end
  end
end
