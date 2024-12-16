defmodule ValentineWeb.WorkspaceLive.Components.AssumptionComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Components.AssumptionComponent

  defp create_assumption(_) do
    assumption = assumption_fixture()
    assigns = %{__changed__: %{}, assumption: assumption, id: "assumption-component"}

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_assumption]

    test "displays assumption numeric_id", %{assigns: assigns} do
      html = render_component(AssumptionComponent, assigns)
      assert html =~ "Assumption #{assigns.assumption.numeric_id}"
    end

    test "displays assumption content", %{assigns: assigns} do
      html = render_component(AssumptionComponent, assigns)
      assert html =~ assigns.assumption.content
    end

    test "displays assumption tags", %{assigns: assigns} do
      html = render_component(AssumptionComponent, assigns)
      assert html =~ hd(assigns.assumption.tags)
    end
  end

  describe "update/2" do
    setup [:create_assumption]

    test "assigns an empty tag", %{assigns: assigns, socket: socket} do
      {:ok, updated_socket} = AssumptionComponent.update(assigns, socket)
      assert updated_socket.assigns.tag == ""
    end
  end

  describe "handle_event/3" do
    setup [:create_assumption]

    test "adds a tag to the assumption", %{assigns: assigns, socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, "new-tag"))

      {:noreply, updated_socket} =
        AssumptionComponent.handle_event("add_tag", %{}, socket)

      assert Enum.member?(updated_socket.assigns.assumption.tags, "new-tag")
    end

    test "does nothing if tag is not set", %{assigns: assigns, socket: socket} do
      socket = Map.put(socket, :assigns, Map.delete(assigns, :tag))

      {:noreply, updated_socket} =
        AssumptionComponent.handle_event("add_tag", %{}, socket)

      assert Enum.count(updated_socket.assigns.assumption.tags) ==
               Enum.count(assigns.assumption.tags)
    end

    test "does nothing if tag already exists", %{assigns: assigns, socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, hd(assigns.assumption.tags)))

      {:noreply, updated_socket} =
        AssumptionComponent.handle_event("add_tag", %{}, socket)

      assert Enum.count(updated_socket.assigns.assumption.tags) ==
               Enum.count(assigns.assumption.tags)
    end

    test "removes a tag from the assumption", %{assigns: assigns, socket: socket} do
      tag = hd(assigns.assumption.tags)
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, tag))

      {:noreply, updated_socket} =
        AssumptionComponent.handle_event("remove_tag", %{"tag" => tag}, socket)

      assert !Enum.member?(updated_socket.assigns.assumption.tags, tag)
    end

    test "sets a tag", %{assigns: assigns, socket: socket} do
      tag = "new-tag"
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, tag))

      {:noreply, updated_socket} =
        AssumptionComponent.handle_event("set_tag", %{"value" => tag}, socket)

      assert updated_socket.assigns.tag == tag
    end

    test "updates comments", %{assigns: assigns, socket: socket} do
      comments = "new comments"
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, comments))

      {:noreply, updated_socket} =
        AssumptionComponent.handle_event(
          "update_comments",
          %{"comments" => comments},
          socket
        )

      assert updated_socket.assigns.assumption.comments == comments
    end
  end
end
