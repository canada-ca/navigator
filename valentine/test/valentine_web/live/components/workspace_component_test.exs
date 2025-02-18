defmodule ValentineWeb.WorkspaceLive.Components.WorkspaceComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Components.WorkspaceComponent

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{assigns: %{current_user: %{}, presence: %{}, workspace: workspace}}
  end

  describe "render" do
    setup [:create_workspace]

    test "displays workspace name", %{assigns: assigns} do
      html = render_component(WorkspaceComponent, assigns)
      assert html =~ assigns.workspace.name
    end

    test "does not show edit/delete button for non-owner", %{assigns: assigns} do
      html = render_component(WorkspaceComponent, assigns)
      refute html =~ "Edit"
      refute html =~ "Delete"
    end

    test "shows edit/delete button for owner", %{assigns: %{workspace: workspace}} do
      html =
        render_component(WorkspaceComponent, %{
          current_user: workspace.owner,
          presence: %{},
          workspace: workspace
        })

      assert html =~ "Edit"
      assert html =~ "Delete"
    end
  end
end
