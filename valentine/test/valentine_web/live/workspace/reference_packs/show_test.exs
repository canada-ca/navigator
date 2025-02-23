defmodule ValentineWeb.WorkspaceLive.ReferencePacks.ShowTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  setup do
    reference_pack_item = reference_pack_item_fixture()
    workspace = workspace_fixture()

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        live_action: nil,
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
        ValentineWeb.WorkspaceLive.ReferencePacks.Show.mount(
          %{
            "collection_id" => reference_pack_item.collection_id,
            "collection_type" => reference_pack_item.collection_type,
            "workspace_id" => workspace_id
          },
          nil,
          socket
        )

      assert socket.assigns.reference_pack == [reference_pack_item]
      assert socket.assigns.selected_references == []
      assert socket.assigns.workspace_id == workspace_id
    end
  end

  describe "handle_params/3 assigns the page title to :index action" do
    test "assigns the page title to 'Reference packs' when live_action is :index" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: :show,
          flash: %{},
          workspace_id: 1
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.ReferencePacks.Show.handle_params(nil, nil, socket)

      assert socket.assigns.page_title == "Reference pack"
    end
  end

  describe "handle_event/2 adds selected references to the workspace" do
    test "adds selected references to the workspace" do
      reference_pack_item = reference_pack_item_fixture()
      workspace = workspace_fixture()

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: nil,
          flash: %{},
          current_user: workspace.owner,
          workspace_id: workspace.id,
          selected_references: [reference_pack_item.id]
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.ReferencePacks.Show.handle_event(
          "add_references",
          nil,
          socket
        )

      assert socket.assigns.flash["info"] == "Added 1 reference items to workspace"

      assert socket.redirected ==
               {:live, :redirect,
                %{
                  kind: :push,
                  to: "/workspaces/#{workspace.id}/reference_packs"
                }}
    end
  end

  describe "handle_info/2" do
    test "assigns selected references to the socket" do
      reference_pack_item = reference_pack_item_fixture()
      workspace = workspace_fixture()

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: nil,
          flash: %{},
          workspace_id: workspace.id
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.ReferencePacks.Show.handle_info(
          {:selected, [reference_pack_item.id]},
          socket
        )

      assert socket.assigns.selected_references == [reference_pack_item.id]
    end
  end
end
