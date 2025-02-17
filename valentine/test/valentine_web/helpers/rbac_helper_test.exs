defmodule ValentineWeb.Helpers.RbacHelperTest do
  use ValentineWeb.ConnCase

  alias ValentineWeb.Helpers.RbacHelper

  describe "init/1" do
    test "returns the default value" do
      assert RbacHelper.init(:default) == :default
    end
  end

  describe "call/2" do
    test "does nothing if workspace_id is not present in conn.params", %{conn: conn} do
      resp_conn = RbacHelper.call(conn, :default)

      assert resp_conn == conn
    end

    test "halts and redirects to /workspaces if user_id is nil" do
      workspace = Valentine.ComposerFixtures.workspace_fixture()

      conn =
        build_conn(:get, "/", %{"workspace_id" => workspace.id})
        |> Plug.Test.init_test_session(%{})

      resp_conn = RbacHelper.call(conn, :default)

      assert resp_conn.status == 302
      assert resp_conn.resp_body =~ "/workspaces"
    end

    test "does nothing if user_id is the owner" do
      workspace = Valentine.ComposerFixtures.workspace_fixture(%{owner: "some owner"})

      conn =
        build_conn(:get, "/", %{"workspace_id" => workspace.id})
        |> Plug.Test.init_test_session(%{"user_id" => "some owner"})

      resp_conn = RbacHelper.call(conn, :default)

      assert resp_conn == conn
    end

    test "does nothing if the user has permission" do
      workspace =
        Valentine.ComposerFixtures.workspace_fixture(%{
          owner: "some owner",
          permissions: %{"some collaborator" => "read"}
        })

      conn =
        build_conn(:get, "/", %{"workspace_id" => workspace.id})
        |> Plug.Test.init_test_session(%{"user_id" => "some collaborator"})

      resp_conn = RbacHelper.call(conn, :default)

      assert resp_conn == conn
    end
  end

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
