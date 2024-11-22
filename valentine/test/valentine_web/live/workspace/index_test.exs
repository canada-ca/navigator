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
          %{"id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Edit Workspace"
      assert updated_socket.assigns.workspace == workspace
    end
  end

  describe "handle_event delete" do
    test "successfully workspace threat", %{socket: socket, workspace: workspace} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Index.handle_event(
          "delete",
          %{"id" => workspace.id},
          socket
        )

      assert updated_socket.assigns.flash["info"] =~ "deleted successfully"
    end

    test "handles delete error", %{socket: socket, workspace: workspace} do
      with_mock Composer,
        get_workspace!: fn _workspace_id -> workspace end,
        delete_workspace: fn _workspace -> {:error, "some error"} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Index.handle_event(
            "delete",
            %{"id" => workspace.id},
            socket
          )

        assert updated_socket.assigns.flash["error"] =~ "Failed to delete"
      end
    end
  end
end
