defmodule ValentineWeb.WorkspaceLive.Collaboration.IndexViewTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  setup do
    user = user_fixture()
    some_user = user_fixture(%{email: "some.other.user@localhost"})

    workspace =
      workspace_fixture(%{
        owner: user.email,
        permissions: %{"some.other.user@localhost" => "write"}
      })

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
      user: user,
      some_user: some_user
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: user.email})

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/collaboration"
        )

      assert html =~ "Collaboration"
      assert html =~ user.email
      assert html =~ some_user.email
    end

    test "states that a collaborator is not the owner and shares the owner", %{
      conn: conn,
      workspace_id: workspace_id,
      user: user,
      some_user: some_user
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: some_user.email})

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/collaboration"
        )

      assert html =~ "You are not the owner of this workspace."
      assert html =~ "write"
      assert html =~ user.email
    end

    test "allows a owner to change the permssion level for a collaborator", %{
      conn: conn,
      workspace_id: workspace_id,
      user: user,
      some_user: some_user
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: user.email})

      {:ok, index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/collaboration"
        )

      assert html =~ "Collaboration"
      assert html =~ user.email
      assert html =~ some_user.email

      assert index_live
             |> element(~s{[id="form-for-#{some_user.email}"]})
             |> render_change(%{"permission" => "none"}) =~
               "<input checked=\"\" class=\"radio-input FormControl-radio\" id=\"#{some_user.email}-__none\" name=\"permission\" type=\"radio\" value=\"none\"/>"
    end
  end
end
