defmodule ValentineWeb.WorkspaceLive.ApiKey.IndexTest do
  use ValentineWeb.ConnCase
  alias Valentine.Composer
  import Mock

  import Valentine.ComposerFixtures

  setup do
    workspace = workspace_fixture()
    api_key = api_key_fixture(%{workspace_id: workspace.id})

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        live_action: nil,
        current_user: workspace.owner,
        flash: %{},
        workspace_id: workspace.id,
        workspace: workspace,
        workspace_permission: "owner"
      }
    }

    {:ok, %{api_key: api_key, socket: socket}}

    %{api_key: api_key, socket: socket, workspace_id: workspace.id, workspace: workspace}
  end

  describe "mount/3" do
    test "assigns workspace_id and initializes api_keys collection", %{
      socket: socket,
      api_key: api_key
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.ApiKey.Index.mount(
          %{"workspace_id" => api_key.workspace_id},
          %{},
          socket
        )

      assert socket.assigns.workspace_id == api_key.workspace_id
      assert hd(socket.assigns.api_keys).id == api_key.id
    end
  end

  describe "handle_params/3" do
    test "sets page title for index action", %{socket: socket, workspace_id: workspace_id} do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ApiKey.Index.handle_params(
          %{"workspace_id" => workspace_id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "API Keys"
      assert updated_socket.assigns.workspace_id == workspace_id
    end

    test "sets page title for generate action", %{socket: socket, workspace_id: workspace_id} do
      socket = put_in(socket.assigns.live_action, :generate)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ApiKey.Index.handle_params(
          %{"workspace_id" => workspace_id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Generate API Key"
      assert updated_socket.assigns.workspace_id == workspace_id
    end
  end

  describe "handle_event delete" do
    test "successfully deletes api_key", %{socket: socket, api_key: api_key} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ApiKey.Index.handle_event(
          "delete",
          %{"id" => api_key.id},
          socket
        )

      assert updated_socket.assigns.flash["info"] =~ "deleted successfully"
    end

    test "handles not found api_key", %{socket: socket, api_key: api_key} do
      with_mock Composer,
        get_api_key: fn _id -> nil end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.ApiKey.Index.handle_event(
            "delete",
            %{"id" => api_key.id},
            socket
          )

        assert updated_socket.assigns.flash["error"] =~ "not found"
      end
    end

    test "handles delete error", %{socket: socket, api_key: api_key} do
      with_mock Composer,
        get_api_key: fn _api_key_id -> api_key end,
        delete_api_key: fn _api_key -> {:error, "some error"} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.ApiKey.Index.handle_event(
            "delete",
            %{"id" => api_key.id},
            socket
          )

        assert updated_socket.assigns.flash["error"] =~ "Failed to delete"
      end
    end
  end

  describe "hande_event flush_api_key" do
    test "successfully flushes api_key", %{socket: socket} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ApiKey.Index.handle_event(
          "flush_api_key",
          nil,
          socket
        )

      assert updated_socket.assigns.recent_api_key == nil
    end
  end

  describe "handle_info {:saved, _api_key}" do
    test "updates api_keys collection", %{
      socket: socket,
      api_key: api_key
    } do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ApiKey.Index.handle_info(
          {ValentineWeb.WorkspaceLive.ApiKey.Components.ApiKeyComponent, {:saved, api_key}},
          socket
        )

      assert hd(updated_socket.assigns.api_keys).id == api_key.id
    end
  end
end
