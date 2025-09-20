defmodule ValentineWeb.WorkspaceLive.BrainstormTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  @create_attrs %{
    type: :threat,
    raw_text: "Sample threat for testing"
  }

  @invalid_attrs %{type: nil, raw_text: nil}

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

      # Start creating a new threat
      assert index_live |> element("button[aria-label=\"Add Threat\"]") |> render_click() =~
               "Enter Threat details"

      # Submit the form
      assert index_live
             |> form("#create", create: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces/#{workspace.id}/brainstorm")

      html = render(index_live)
      assert html =~ "Item created successfully"
      assert html =~ @create_attrs.raw_text
    end

    test "updates brainstorm item", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Start editing
      assert index_live |> element("[phx-value-id=\"#{brainstorm_item.id}\"]") |> render_click() =~
               "Save"

      # Submit the edit form
      assert index_live
             |> form("#update", update: %{item_id: brainstorm_item.id, text: "Updated threat text"})
             |> render_submit()

      html = render(index_live)
      assert html =~ "Item updated successfully"
      assert html =~ "Updated threat text"
    end

    test "deletes brainstorm item", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert index_live |> element("[phx-click=\"delete_item\"][phx-value-id=\"#{brainstorm_item.id}\"]") |> render_click()
      
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
             |> element("[phx-click=\"update_status\"][phx-value-id=\"#{brainstorm_item.id}\"][phx-value-status=\"clustered\"]") 
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
             |> form("[phx-change=\"filter\"]", %{status: "archived"})
             |> render_change()

      html = render(index_live)
      assert html =~ "No Threat items"
    end

    test "searches brainstorm items", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Search for specific text
      assert index_live
             |> form("[phx-change=\"filter\"]", %{search: "Test"})
             |> render_change()

      html = render(index_live)
      assert html =~ brainstorm_item.raw_text

      # Search for non-existent text
      assert index_live
             |> form("[phx-change=\"filter\"]", %{search: "NonExistent"})
             |> render_change()

      html = render(index_live)
      refute html =~ brainstorm_item.raw_text
    end

    test "clears filters", %{conn: conn, workspace: workspace} do
      _brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Apply a filter first
      assert index_live
             |> form("[phx-change=\"filter\"]", %{search: "NonExistent"})
             |> render_change()

      # Clear filters
      assert index_live |> element("[phx-click=\"clear_filters\"]") |> render_click()

      html = render(index_live)
      assert html =~ "Test threat"
    end
  end

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end
end