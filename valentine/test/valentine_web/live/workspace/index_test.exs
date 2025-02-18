defmodule ValentineWeb.WorkspaceLive.IndexTest do
  use ValentineWeb.ConnCase
  import Valentine.ComposerFixtures
  alias Valentine.Composer
  import Mock

  setup do
    workspace = workspace_fixture()

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          current_user: workspace.owner,
          live_action: nil,
          filters: %{},
          flash: %{}
        }
      }

    {:ok, %{workspace: workspace, socket: socket}}
  end

  describe "mount/3" do
    test "assigns workspaces list", %{
      socket: socket,
      workspace: workspace
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.Index.mount(
          %{},
          %{},
          socket
        )

      assert socket.assigns.workspaces == [workspace]
    end
  end

  describe "handle_params/3" do
    test "sets page title for index action", %{socket: socket} do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_params(
          %{},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Listing Workspaces"
    end

    test "sets page title for new action", %{socket: socket} do
      socket = put_in(socket.assigns.live_action, :new)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_params(
          %{},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "New Workspace"
      assert updated_socket.assigns.workspace == %Valentine.Composer.Workspace{}
    end

    test "sets page title for edit action", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.live_action, :edit)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_params(
          %{"workspace_id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Edit Workspace"
      assert updated_socket.assigns.workspace == workspace
    end

    test "sets page title for import action", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.live_action, :import)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_params(
          %{"workspace_id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Import Workspace"
      assert updated_socket.assigns.workspace == %Valentine.Composer.Workspace{}
    end
  end

  describe "handle_event delete" do
    test "successfully workspace threat", %{socket: socket, workspace: workspace} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_event(
          "delete",
          %{"workspace_id" => workspace.id},
          socket
        )

      assert updated_socket.assigns.flash["info"] =~ "deleted successfully"
    end

    test "does not delete if the user is not the owner", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.current_user, "not the owner")

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_event(
          "delete",
          %{"workspace_id" => workspace.id},
          socket
        )

      assert updated_socket.assigns.flash["error"] =~ "not the owner"
    end

    test "handles delete error", %{socket: socket, workspace: workspace} do
      with_mock Composer,
        get_workspace!: fn _workspace_id -> workspace end,
        delete_workspace: fn _workspace -> {:error, "some error"} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Index.handle_event(
            "delete",
            %{"workspace_id" => workspace.id},
            socket
          )

        assert updated_socket.assigns.flash["error"] =~ "Failed to delete"
      end
    end
  end

  describe "handle_info/2" do
    test "sets workspaces list after saving workspace", %{socket: socket, workspace: workspace} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_info(
          {ValentineWeb.WorkspaceLive.FormComponent, {:saved, workspace}},
          socket
        )

      assert updated_socket.assigns.workspaces == [workspace]
    end
  end
end
