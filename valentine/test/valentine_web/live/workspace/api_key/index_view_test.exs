defmodule ValentineWeb.WorkspaceLive.ApiKey.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias Valentine.Composer.ApiKeys

  alias Valentine.Composer.Workspaces
  @create_attrs %{label: "some label"}

  defp create_api_key(_) do
    api_key = api_key_fixture()
    %{api_key: api_key, workspace_id: api_key.workspace_id}
  end

  describe "Index" do
    setup [:create_api_key]

    test "states that a collaborator is not the owner and shares the owner", %{
      conn: conn
    } do
      user = user_fixture()
      some_user = user_fixture(%{email: "some.other.user@localhost"})

      workspace =
        workspace_fixture(%{
          owner: user.email,
          permissions: %{"some.other.user@localhost" => "write"}
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: some_user.email})

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace.id}/api_keys"
        )

      assert html =~ "You are not the owner of this workspace."
    end

    test "lists all api_keys", %{
      conn: conn,
      api_key: api_key,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace_id}/api_keys")

      assert html =~ "Your API keys"
      assert html =~ api_key.label
    end

    test "saves new api_keys", %{conn: conn, workspace_id: workspace_id} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace_id}/api_keys")

      assert index_live |> element("button", "Generate API Key") |> render_click() =~
               "Generate API Key"

      assert_patch(index_live, ~p"/workspaces/#{workspace_id}/api_keys/generate")

      assert index_live
             |> form("#api-keys-form",
               api_key: @create_attrs
             )
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces/#{workspace_id}/api_keys")

      html = render(index_live)
      assert html =~ "API Key created successfully"
      assert html =~ "some label"
    end

    test "ignores forged workspace, owner, and status fields", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      workspace = Workspaces.get_workspace!(workspace_id)
      other_workspace = workspace_fixture(%{owner: "other.owner@localhost"})
      conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: workspace.owner})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/api_keys")

      index_live
      |> element("#generate-api-key")
      |> render_click()

      index_live
      |> element("#api-keys-form")
      |> render_submit(%{
        "api_key" => %{
          "label" => "forged submission",
          "owner" => other_workspace.owner,
          "status" => "revoked",
          "workspace_id" => other_workspace.id
        }
      })

      api_key =
        workspace.id
        |> ApiKeys.list_api_keys_by_workspace()
        |> Enum.find(&(&1.label == "forged submission"))

      assert api_key.owner == workspace.owner
      assert api_key.status == :active
      assert api_key.workspace_id == workspace.id
      assert ApiKeys.list_api_keys_by_workspace(other_workspace.id) == []
    end

    test "deletes api_key in listing", %{
      conn: conn,
      api_key: api_key,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace_id}/api_keys")

      assert index_live
             |> element("#delete-api-key-#{api_key.id}")
             |> render_click()

      refute has_element?(index_live, "#api-keys-#{api_key.id}")
    end
  end
end
