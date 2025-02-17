defmodule ValentineWeb.WorkspaceLive.ShowTest do
  use ValentineWeb.ConnCase
  import Valentine.ComposerFixtures

  setup do
    workspace = workspace_fixture()

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: nil
        }
      }

    {:ok, %{workspace: workspace, socket: socket}}
  end

  describe "mount/3" do
    test "mounts the socket", %{socket: socket} do
      {:ok, updated_socket} = ValentineWeb.WorkspaceLive.Show.mount(%{}, %{}, socket)
      assert updated_socket == socket
    end
  end

  describe "handle_params/3" do
    test "sets page title for show action", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.live_action, :show)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Show.handle_params(
          %{"workspace_id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Show Workspace"
    end

    test "assigns workspace", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.live_action, :show)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Show.handle_params(
          %{"workspace_id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.workspace.id == workspace.id
    end
  end
end
