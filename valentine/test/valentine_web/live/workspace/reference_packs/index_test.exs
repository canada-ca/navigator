defmodule ValentineWeb.WorkspaceLive.ReferencePacks.IndexTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  setup do
    reference_pack_item = reference_pack_item_fixture()
    workspace = workspace_fixture()

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        live_action: nil,
        current_user: workspace.owner,
        flash: %{},
        workspace_id: workspace.id
      }
    }

    %{
      reference_pack_item: reference_pack_item,
      socket: socket,
      workspace_id: workspace.id
    }
  end

  describe "mount/3" do
    test "mounts the component and assigns the correct assigns", %{
      reference_pack_item: reference_pack_item,
      workspace_id: workspace_id,
      socket: socket
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.ReferencePacks.Index.mount(
          %{"workspace_id" => workspace_id},
          nil,
          socket
        )

      assert socket.assigns.reference_packs == [
               %{
                 count: 1,
                 collection_id: reference_pack_item.collection_id,
                 collection_name: reference_pack_item.collection_name,
                 collection_type: reference_pack_item.collection_type
               }
             ]

      assert socket.assigns.workspace_id == workspace_id
    end
  end

  describe "handle_event/3" do
    test "deletes a reference pack collection and assigns the correct assigns", %{
      reference_pack_item: reference_pack_item,
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.ReferencePacks.Index.handle_event(
          "delete",
          %{
            "id" => reference_pack_item.collection_id,
            "type" => reference_pack_item.collection_type
          },
          socket
        )

      assert socket.assigns.reference_packs == []
      assert socket.assigns.flash["info"] == "Reference pack deleted successfully"
    end
  end

  describe "handle_params/3 assigns the page title to :index action" do
    test "assigns the page title to 'Reference packs' when live_action is :index" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: :index,
          flash: %{},
          workspace_id: 1
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.ReferencePacks.Index.handle_params(nil, nil, socket)

      assert socket.assigns.page_title == "Reference packs"
    end

    test "assigns the page title to 'Import reference pack' when live_action is :import" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: :import,
          flash: %{},
          workspace_id: 1
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.ReferencePacks.Index.handle_params(nil, nil, socket)

      assert socket.assigns.page_title == "Import reference pack"
    end
  end
end
