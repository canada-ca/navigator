defmodule ValentineWeb.WorkspaceLive.BrainstormTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  @create_attrs %{
    type: "threat",
    text: "Sample threat for testing"
  }

  defp create_brainstorm_item(workspace) do
    brainstorm_item_fixture(%{workspace_id: workspace.id, type: :threat, raw_text: "Test threat"})
  end

  describe "Index" do
    setup [:create_workspace]

    test "lists all brainstorm items", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert html =~ "Brainstorm Board"
      assert html =~ brainstorm_item.raw_text
    end

    test "creates brainstorm item", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Submit the form directly since it's always visible
      assert index_live
             |> form("form[phx-submit=\"create_item\"]", %{
               type: "threat",
               text: @create_attrs.text
             })
             |> render_submit()

      html = render(index_live)
      assert html =~ @create_attrs.text
    end

    test "updates brainstorm item", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Start editing by clicking on the item text div (not the menu item)
      assert index_live
             |> element(
               "div[phx-click=\"start_editing\"][phx-value-id=\"#{brainstorm_item.id}\"]"
             )
             |> render_click() =~
               "Save"

      # Submit the edit form
      assert index_live
             |> form(
               "form[phx-submit=\"update_item\"]",
               %{item_id: brainstorm_item.id, text: "Updated threat text"}
             )
             |> render_submit()

      html = render(index_live)
      assert html =~ "Item updated successfully"
      assert html =~ "Updated threat text"
    end

    test "deletes brainstorm item", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert index_live
             |> element("[phx-click=\"delete_item\"][phx-value-id=\"#{brainstorm_item.id}\"]")
             |> render_click()

      html = render(index_live)
      assert html =~ "Item deleted"
      refute html =~ brainstorm_item.raw_text
    end

    test "updates item status", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Update status to clustered
      assert index_live
             |> element(
               "[phx-click=\"update_status\"][phx-value-id=\"#{brainstorm_item.id}\"][phx-value-status=\"clustered\"]"
             )
             |> render_click()

      html = render(index_live)
      assert html =~ "Status updated successfully"
      assert html =~ "Clustered"
    end

    test "filters brainstorm items by status", %{conn: conn, workspace: workspace} do
      _draft_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Filter by archived status (should show no items)
      assert index_live
             |> element("select[id=\"status-filter\"]")
             |> render_change(%{filter_status: "archived"})

      html = render(index_live)
      # Should show empty state since no archived items exist
      assert html =~ "Start Brainstorming!"
    end

    test "searches brainstorm items", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Search for specific text
      assert index_live
             |> element("input[id=\"search-filter\"]")
             |> render_change(%{search: "Test"})

      html = render(index_live)
      assert html =~ brainstorm_item.raw_text

      # Search for non-existent text
      assert index_live
             |> element("input[id=\"search-filter\"]")
             |> render_change(%{search: "NonExistent"})

      html = render(index_live)
      # Should show empty state when no results
      assert html =~ "Start Brainstorming!"
    end

    test "clears filters", %{conn: conn, workspace: workspace} do
      _brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Apply a filter first
      assert index_live
             |> element("input[id=\"search-filter\"]")
             |> render_change(%{search: "NonExistent"})

      # Clear filters
      assert index_live |> element("button", "Clear") |> render_click()

      html = render(index_live)
      assert html =~ "Test threat"
    end
  end

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end
end
