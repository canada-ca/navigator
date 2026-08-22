defmodule ValentineWeb.WorkspaceLive.Components.LabelSelectComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest

  alias ValentineWeb.WorkspaceLive.Components.LabelSelectComponent

  defp create_label_select(_) do
    assigns = %{
      __changed__: %{},
      default_value: "some default value",
      field: "some field",
      icon: "some icon",
      items: [],
      show_dropdown: false,
      id: "label-select-component",
      value: "some value"
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_label_select]

    test "renders the component properly", %{assigns: assigns} do
      html = render_component(LabelSelectComponent, assigns)
      assert html =~ "some icon"
      assert html =~ "Some value"
    end

    test "if show_dropdown is true, renders the dropdown", %{assigns: assigns} do
      assigns = Map.put(assigns, :show_dropdown, true)
      html = render_component(LabelSelectComponent, assigns)
      assert html =~ "ActionMenu-modal"
    end
  end

  describe "mount/1" do
    test "mounts the component with the correct assigns" do
      socket = %Phoenix.LiveView.Socket{}
      {:ok, socket} = LabelSelectComponent.mount(socket)
      assert socket.assigns.selected_item == nil
      assert socket.assigns.items == []
      assert socket.assigns.show_dropdown == false
    end
  end

  describe "handle_event/3 selected item" do
    test "selects the item based on the id" do
      workspace = Valentine.ComposerFixtures.workspace_fixture()

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          field: "some field",
          id: "label-select-component",
          items: [{:item_1, nil}, {:item_2, nil}, {:item_3, nil}],
          workspace_id: workspace.id,
          current_user: workspace.owner
        }
      }

      {:noreply, socket} =
        LabelSelectComponent.handle_event("select_item", %{"id" => :item_1}, socket)

      assert socket.assigns.show_dropdown == false
    end

    test "selects the item based on the id when a parent_id is set" do
      workspace = Valentine.ComposerFixtures.workspace_fixture()

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          field: "some field",
          id: "label-select-component",
          items: [{:item_1, nil}, {:item_2, nil}, {:item_3, nil}],
          parent_id: %Phoenix.LiveComponent.CID{cid: 1},
          workspace_id: workspace.id,
          current_user: workspace.owner
        }
      }

      {:noreply, socket} =
        LabelSelectComponent.handle_event("select_item", %{"id" => :item_1}, socket)

      assert socket.assigns.show_dropdown == false
    end
  end

  describe "handle_event/3 toggle dropdown" do
    test "toggles the dropdown" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          show_dropdown: false
        }
      }

      {:noreply, socket} =
        LabelSelectComponent.handle_event("toggle_dropdown", %{}, socket)

      assert socket.assigns.show_dropdown == true
    end
  end
end
