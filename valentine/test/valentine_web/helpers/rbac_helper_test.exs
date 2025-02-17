defmodule ValentineWeb.Helpers.RbacHelperTest do
  use ValentineWeb.ConnCase

  alias ValentineWeb.Helpers.RbacHelper

  describe "on_mount/4" do
    test "paths that contain a workspace_id parameter check rbac_permissions" do
      workspace = Valentine.ComposerFixtures.workspace_fixture()

      {:cont, socket} =
        RbacHelper.on_mount(
          :default,
          %{"workspace_id" => workspace.id},
          %{},
          %Phoenix.LiveView.Socket{
            assigns: %{__changed__: %{}, current_user: workspace.owner}
          }
        )

      assert socket.assigns.workspace_permission == "owner"
    end

    test "paths that do not contain a workspace_id parameter do not check rbac_permissions" do
      {:cont, socket} =
        RbacHelper.on_mount(
          :default,
          %{},
          %{},
          %Phoenix.LiveView.Socket{
            assigns: %{__changed__: %{}, current_user: nil}
          }
        )

      refute Map.has_key?(socket.assigns, :workspace_permission)
    end

    test "paths that contain a workspace_id parameter and the user does not have permission" do
      workspace = Valentine.ComposerFixtures.workspace_fixture()

      {:halt, redirect} =
        RbacHelper.on_mount(
          :default,
          %{"workspace_id" => workspace.id},
          %{},
          %Phoenix.LiveView.Socket{
            assigns: %{__changed__: %{}, current_user: nil}
          }
        )

      assert redirect ==
               Phoenix.LiveView.redirect(
                 %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, current_user: nil}},
                 to: "/workspaces"
               )
    end
  end
end
