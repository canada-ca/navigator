defmodule ValentineWeb.WorkspaceLive.Threat.IndexTest do
  use ValentineWeb.ConnCase
  alias Valentine.Composer.Threats
  import Valentine.ComposerFixtures

  import Mock

  setup do
    workspace = workspace_fixture()
    threat = threat_fixture(%{workspace_id: workspace.id})

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: nil,
          filters: %{},
          flash: %{},
          current_user: workspace.owner,
          workspace_id: workspace.id
        }
      }

    {:ok, %{workspace: workspace, threat: threat, socket: socket}}
  end

  describe "mount/3" do
    test "assigns workspace_id and initializes threats stream", %{
      socket: socket,
      workspace: workspace
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.Threat.Index.mount(
          %{"workspace_id" => workspace.id},
          %{},
          socket
        )

      assert socket.assigns.workspace_id == workspace.id
      assert Map.has_key?(socket.assigns, :threats)
    end
  end

  describe "handle_params/3" do
    test "sets page title for index action", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Index.handle_params(
          %{"workspace_id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Listing threats"
      assert updated_socket.assigns.workspace_id == workspace.id
    end
  end

  describe "handle_event delete" do
    test "successfully deletes threat", %{socket: socket, threat: threat} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Index.handle_event(
          "delete",
          %{"id" => threat.id},
          socket
        )

      assert updated_socket.assigns.flash["info"] =~ "deleted successfully"
    end

    test "handles not found threat", %{socket: socket} do
      with_mock Threats,
        get_threat_for_workspace: fn _workspace_id, _id -> nil end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Threat.Index.handle_event(
            "delete",
            %{"id" => nil},
            socket
          )

        assert updated_socket.assigns.flash["error"] =~ "not found"
      end
    end

    test "handles delete error", %{socket: socket, threat: threat} do
      with_mock Threats,
        get_threat_for_workspace: fn _workspace_id, _id -> threat end,
        delete_threat: fn _threat -> {:error, "some error"} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Threat.Index.handle_event(
            "delete",
            %{"id" => threat.id},
            socket
          )

        assert updated_socket.assigns.flash["error"] =~ "Failed to delete"
      end
    end
  end

  describe "handle_event/3" do
    test "clears filters", %{socket: socket} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Index.handle_event(
          "clear_filters",
          nil,
          socket
        )

      assert updated_socket.assigns.filters == %{}
    end
  end

  describe "handle_info/2" do
    test "updates filters on filter changes", %{socket: socket} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Index.handle_info(
          {:update_filter, %{status: [:resolved]}},
          socket
        )

      assert updated_socket.assigns.filters == %{status: [:resolved]}
    end

    test "updates threats stream on workspace changes", %{socket: socket, workspace: workspace} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Index.handle_info(
          %{topic: "workspace_" <> workspace.id},
          socket
        )

      assert Map.has_key?(updated_socket.assigns, :threats)
    end
  end
end
