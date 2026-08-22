defmodule ValentineWeb.WorkspaceLive.Architecture.IndexTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  setup do
    workspace = workspace_fixture()
    architecture = architecture_fixture(workspace_id: workspace.id)

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        touched: false,
        current_user: workspace.owner,
        live_action: nil,
        flash: %{},
        workspace_id: workspace.id
      }
    }

    %{
      architecture: architecture,
      socket: socket,
      workspace_id: workspace.id,
      workspace: workspace
    }
  end

  describe "mount/3" do
    test "mounts the component and assigns the correct assigns", %{
      workspace_id: workspace_id,
      architecture: architecture,
      socket: socket
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.Architecture.Index.mount(
          %{"workspace_id" => workspace_id},
          nil,
          socket
        )

      assert socket.assigns.architecture == architecture
      assert socket.assigns.touched == false
      assert socket.assigns.workspace_id == workspace_id
    end
  end

  describe "handle_params/3 assigns the page title to :index action" do
    test "assigns the page title to 'Architecture' when live_action is :index" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: :index,
          flash: %{},
          workspace_id: 1
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.Architecture.Index.handle_params(nil, nil, socket)

      assert socket.assigns.page_title == "Architecture"
    end
  end

  describe "handle_info/2" do
    test "handles local changes and broadcasts the change", %{
      architecture: architecture,
      socket: socket
    } do
      delta = %{"ops" => "some delta"}

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.Architecture.Index.handle_info(
          {:quill_change, delta},
          socket
        )

      assert socket.assigns.touched == true

      assert [delta["ops"]] ==
               Valentine.Composer.Architecture.get_cache(architecture.workspace_id)
    end

    test "handles remote changes", %{
      socket: socket
    } do
      delta = %{
        event: :quill_change,
        payload: %{"ops" => "some delta"}
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.Architecture.Index.handle_info(
          delta,
          socket
        )

      assert socket.assigns.touched == true

      assert socket.private == %{
               live_temp: %{
                 push_events: [["updateQuill", %{event: "text_change", payload: delta.payload}]]
               }
             }
    end

    test "handles remote save button clicked", %{
      architecture: architecture,
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.Architecture.Index.handle_info(
          %{event: :quill_saved},
          socket
        )

      assert socket.assigns.touched == false

      assert socket.private == %{
               live_temp: %{
                 push_events: [
                   [
                     "updateQuill",
                     %{
                       event: "blob_change",
                       payload: architecture.content
                     }
                   ]
                 ]
               }
             }
    end

    test "handles save button clicked", %{
      architecture: architecture,
      socket: socket
    } do
      content = "some content"

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.Architecture.Index.handle_info(
          {:quill_save, content},
          socket
        )

      assert socket.assigns.touched == false

      assert Valentine.Composer.Architecture.get_cache(architecture.workspace_id) == []
    end

    test "reader changes and saves do not alter cache or content", %{
      architecture: architecture,
      socket: socket,
      workspace: workspace
    } do
      {:ok, _workspace} =
        Valentine.Composer.Workspaces.update_workspace_permissions(
          workspace,
          workspace.owner,
          "reader@localhost",
          "read"
        )

      Valentine.Composer.Architecture.flush_cache(workspace.id)
      socket = put_in(socket.assigns.current_user, "reader@localhost")

      assert {:noreply, _socket} =
               ValentineWeb.WorkspaceLive.Architecture.Index.handle_info(
                 {:quill_change, %{"ops" => [%{"insert" => "forged"}]}},
                 socket
               )

      assert {:noreply, _socket} =
               ValentineWeb.WorkspaceLive.Architecture.Index.handle_info(
                 {:quill_save, "forged content"},
                 socket
               )

      assert Valentine.Composer.Architecture.get_cache(workspace.id) == []

      reloaded = Valentine.Composer.Workspaces.get_workspace!(workspace.id, [:architecture])
      assert reloaded.architecture.content == architecture.content
    end
  end
end
