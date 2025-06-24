defmodule ValentineWeb.WorkspaceLive.Assumption.IndexTest do
  use ValentineWeb.ConnCase
  alias Valentine.Composer
  import Mock

  import Valentine.ComposerFixtures

  setup do
    workspace = workspace_fixture()
    assumption = assumption_fixture(%{workspace_id: workspace.id})

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        live_action: nil,
        current_user: workspace.owner,
        flash: %{},
        workspace_id: workspace.id,
        workspace: workspace
      }
    }

    {:ok, %{assumption: assumption, socket: socket}}

    %{assumption: assumption, socket: socket, workspace_id: workspace.id, workspace: workspace}
  end

  describe "mount/3" do
    test "assigns workspace_id and initializes assumptions collection", %{
      socket: socket,
      assumption: assumption
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.Assumption.Index.mount(
          %{"workspace_id" => assumption.workspace_id},
          %{},
          socket
        )

      assert socket.assigns.workspace_id == assumption.workspace_id
      assert hd(socket.assigns.assumptions).id == assumption.id
    end
  end

  describe "handle_params/3" do
    test "sets page title for index action", %{socket: socket, workspace_id: workspace_id} do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Assumption.Index.handle_params(
          %{"workspace_id" => workspace_id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Listing Assumptions"
      assert updated_socket.assigns.workspace_id == workspace_id
    end
  end

  describe "handle_info {:saved, _assumption}" do
    test "updates assumptions collection", %{
      socket: socket,
      assumption: assumption
    } do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Assumption.Index.handle_info(
          {ValentineWeb.WorkspaceLive.Assumption.Components.FormComponent, {:saved, assumption}},
          socket
        )

      assert hd(updated_socket.assigns.assumptions).id == assumption.id
    end

    test "updates filters on filter changes", %{socket: socket} do
      with_mocks([
        {
          Composer,
          [],
          list_assumptions_by_workspace: fn _, _ ->
            [%{id: 1, title: "Updated Assumption"}]
          end
        }
      ]) do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Assumption.Index.handle_info(
            {:update_filter, %{status: "open"}},
            socket
          )

        assert updated_socket.assigns.filters == %{status: "open"}
      end
    end
  end

  describe "handle_event delete" do
    test "successfully deletes assumption", %{socket: socket, assumption: assumption} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Assumption.Index.handle_event(
          "delete",
          %{"id" => assumption.id},
          socket
        )

      assert updated_socket.assigns.flash["info"] =~ "deleted successfully"
    end
  end

  test "handles not found assumption", %{socket: socket, assumption: assumption} do
    with_mock Composer,
      get_assumption!: fn _id -> nil end do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Assumption.Index.handle_event(
          "delete",
          %{"id" => assumption.id},
          socket
        )

      assert updated_socket.assigns.flash["error"] =~ "not found"
    end
  end

  test "handles delete error", %{socket: socket, assumption: assumption} do
    with_mock Composer,
      get_assumption!: fn _assumption_id -> assumption end,
      delete_assumption: fn _assumption -> {:error, "some error"} end do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Assumption.Index.handle_event(
          "delete",
          %{"id" => assumption.id},
          socket
        )

      assert updated_socket.assigns.flash["error"] =~ "Failed to delete"
    end
  end

  test "clears filters", %{socket: socket} do
    with_mocks([
      {
        Composer,
        [],
        list_assumptions_by_workspace: fn _, _ ->
          [%{id: 1, title: "Updated Assumption"}]
        end
      }
    ]) do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Assumption.Index.handle_event(
          "clear_filters",
          nil,
          socket
        )

      assert updated_socket.assigns.filters == %{}
    end
  end
end
