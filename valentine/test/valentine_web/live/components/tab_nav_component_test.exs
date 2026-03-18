defmodule ValentineWeb.WorkspaceLive.Components.TabNavComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest

  alias ValentineWeb.WorkspaceLive.Components.TabNavComponent

  defp setup_component(_) do
    assigns = %{
      __changed__: %{},
      id: "tab-nav-component"
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  defp tab_slot() do
    [
      %{
        __slot__: :tab,
        inner_block: fn _, tab -> "Content for #{tab}" end
      }
    ]
  end

  describe "mount/1" do
    test "mounts the component with the correct assigns" do
      {:ok, socket} = TabNavComponent.mount(%Phoenix.LiveView.Socket{})

      assert socket.assigns.tabs == []
      assert socket.assigns.current_tab == ""
    end
  end

  describe "render/1" do
    setup [:setup_component]

    test "renders the component properly", %{assigns: assigns} do
      assigns =
        Map.merge(assigns, %{
          tab_content: tab_slot(),
          tabs: [%{label: "Tab 1", id: "tab-1"}, %{label: "Tab 2", id: "tab-2"}]
        })

      html = render_component(TabNavComponent, assigns)

      assert html =~ "Tab 1"
      assert html =~ "Tab 2"
      assert html =~ "Content for tab-1"
    end
  end

  describe "handle_event/3" do
    setup [:setup_component]

    test "sets the current tab", %{socket: socket} do
      socket =
        Map.merge(socket, %{
          assigns: %{
            __changed__: %{},
            current_tab: nil,
            tabs: [%{id: "tab-1", label: "Tab 1"}]
          }
        })

      {:noreply, socket} = TabNavComponent.handle_event("set_tab", %{"item" => "tab-1"}, socket)

      assert socket.assigns.current_tab == "tab-1"
    end

    test "attempting to set an invalid tab ID is ignored", %{socket: socket} do
      socket =
        Map.merge(socket, %{
          assigns: %{
            __changed__: %{},
            current_tab: "tab-1",
            tabs: [
              %{id: "tab-1", label: "Tab 1"},
              %{id: "tab-2", label: "Tab 2"}
            ]
          }
        })

      {:noreply, new_socket} =
        TabNavComponent.handle_event(
          "set_tab",
          %{"item" => "nonexistent-tab"},
          socket
        )

      # Behavior: Component should ignore invalid tab requests and maintain current state
      assert new_socket.assigns.current_tab == "tab-1"
    end

    test "setting a valid tab ID changes the active tab", %{socket: socket} do
      socket =
        Map.merge(socket, %{
          assigns: %{
            __changed__: %{},
            current_tab: "tab-1",
            tabs: [
              %{id: "tab-1", label: "Tab 1"},
              %{id: "tab-2", label: "Tab 2"}
            ]
          }
        })

      {:noreply, new_socket} =
        TabNavComponent.handle_event(
          "set_tab",
          %{"item" => "tab-2"},
          socket
        )

      # Behavior: User should be able to switch to valid tabs
      assert new_socket.assigns.current_tab == "tab-2"
    end
  end

  describe "update/2 - current_tab initialization and validation" do
    setup [:setup_component]

    test "invalid current_tab in assigns is rejected and defaults to first tab", %{
      socket: socket
    } do
      assigns = %{
        tabs: [%{id: "valid-1", label: "Tab 1"}, %{id: "valid-2", label: "Tab 2"}],
        current_tab: "nonexistent-tab"
      }

      {:ok, socket} = TabNavComponent.update(assigns, socket)

      # Behavior: Component should fall back to a valid tab when given invalid input
      assert socket.assigns.current_tab == "valid-1"
    end

    test "valid current_tab in socket state is preserved", %{socket: socket} do
      socket =
        socket
        |> put_in([Access.key(:assigns), :current_tab], "valid-2")
        |> put_in([Access.key(:assigns), :tabs], [
          %{id: "valid-1", label: "Tab 1"},
          %{id: "valid-2", label: "Tab 2"}
        ])

      assigns = %{tabs: socket.assigns.tabs}

      {:ok, socket} = TabNavComponent.update(assigns, socket)

      # Behavior: Component should remember user's last selected tab across updates
      assert socket.assigns.current_tab == "valid-2"
    end

    test "valid current_tab in new assigns takes precedence over socket state", %{socket: socket} do
      socket =
        socket
        |> put_in([Access.key(:assigns), :current_tab], "valid-1")
        |> put_in([Access.key(:assigns), :tabs], [
          %{id: "valid-1", label: "Tab 1"},
          %{id: "valid-2", label: "Tab 2"}
        ])

      assigns = %{
        tabs: socket.assigns.tabs,
        current_tab: "valid-2"
      }

      {:ok, socket} = TabNavComponent.update(assigns, socket)

      # Behavior: Parent component can override current tab selection
      assert socket.assigns.current_tab == "valid-2"
    end

    test "empty tabs list defaults to empty string for current_tab", %{socket: socket} do
      assigns = %{tabs: []}

      {:ok, socket} = TabNavComponent.update(assigns, socket)

      # Behavior: Component gracefully handles empty tab list
      assert socket.assigns.current_tab == ""
    end
  end
end
