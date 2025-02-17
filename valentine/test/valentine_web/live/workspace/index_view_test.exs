defmodule ValentineWeb.WorkspaceLive.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end

  describe "Index" do
    setup [:create_workspace]

    test "lists all workspaces", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces")

      assert html =~ "Listing Workspaces"
      assert html =~ workspace.name
    end

    test "saves new workspaces", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live |> element("button", "New Workspace") |> render_click() =~
               "New Workspace"

      assert_patch(index_live, ~p"/workspaces/new")

      assert index_live
             |> form("#workspaces-form",
               workspace: @create_attrs
             )
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces")

      html = render(index_live)
      assert html =~ "Workspace created successfully"
      assert html =~ "some name"
    end

    test "updates workspace in listing", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#edit-workspace-#{workspace.id}")
             |> render_click() =~
               "Edit Workspace"

      assert_patch(index_live, ~p"/workspaces/#{workspace.id}/edit")

      assert index_live
             |> form("#workspaces-form", workspace: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces")

      html = render(index_live)
      assert html =~ "Workspace updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes workspace in listing", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#delete-workspace-#{workspace.id}")
             |> render_click()

      refute has_element?(index_live, "#workspaces-#{workspace.id}")
    end

    test "imports workspace in listing", %{
      conn: conn
    } do
      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#import-workspace-btn")
             |> render_click() =~
               "Import Workspace"

      assert_patch(index_live, ~p"/workspaces/import")
    end
  end
end
