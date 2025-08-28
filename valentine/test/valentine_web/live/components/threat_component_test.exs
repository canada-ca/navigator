defmodule ValentineWeb.WorkspaceLive.Components.ThreatComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Components.ThreatComponent

  defp create_threat(_) do
    threat = threat_fixture()

    assigns = %{__changed__: %{}, threat: threat, id: "threat-component"}

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render" do
    setup [:create_threat]

    test "displays threat numeric_id", %{assigns: assigns} do
      html = render_component(ThreatComponent, assigns)
      assert html =~ "Threat #{assigns.threat.numeric_id}"
    end

    test "displays threat source", %{assigns: assigns} do
      html = render_component(ThreatComponent, assigns)
      assert html =~ assigns.threat.threat_source
    end

    test "displays threat prerequisites", %{assigns: assigns} do
      html = render_component(ThreatComponent, assigns)
      assert html =~ assigns.threat.prerequisites
    end

    test "displays threat action", %{assigns: assigns} do
      html = render_component(ThreatComponent, assigns)
      assert html =~ assigns.threat.threat_action
    end

    test "displays threat impact", %{assigns: assigns} do
      html = render_component(ThreatComponent, assigns)
      assert html =~ assigns.threat.threat_impact
    end

    test "displays threat impacted goal if it set", %{assigns: assigns} do
      html = render_component(ThreatComponent, assigns)
      assert html =~ hd(assigns.threat.impacted_goal)
    end

    test "do not display threat goal if it is not set", %{assigns: assigns} do
      threat = Map.put(assigns.threat, :impacted_goal, nil)
      assigns = Map.put(assigns, :threat, threat)
      html = render_component(ThreatComponent, assigns)
      refute html =~ "reduced"
    end

    test "display impacted assets", %{assigns: assigns} do
      html = render_component(ThreatComponent, assigns)
      assert html =~ hd(assigns.threat.impacted_assets)
    end

    test "displays a :low priority badge", %{assigns: assigns} do
      assigns = Map.put(assigns, :threat, Map.put(assigns.threat, :priority, :low))
      html = render_component(ThreatComponent, assigns)
      assert html =~ "Low"
    end

    test "displays a :medium priority badge", %{assigns: assigns} do
      assigns = Map.put(assigns, :threat, Map.put(assigns.threat, :priority, :medium))
      html = render_component(ThreatComponent, assigns)
      assert html =~ "Medium"
    end

    test "displays a :high priority badge", %{assigns: assigns} do
      assigns = Map.put(assigns, :threat, Map.put(assigns.threat, :priority, :high))
      html = render_component(ThreatComponent, assigns)
      assert html =~ "High"
    end

    test "displays an :identified status badge", %{assigns: assigns} do
      assigns = Map.put(assigns, :threat, Map.put(assigns.threat, :status, :identified))
      html = render_component(ThreatComponent, assigns)
      assert html =~ "Identified"
    end

    test "displays a :resolved status badge", %{assigns: assigns} do
      assigns = Map.put(assigns, :threat, Map.put(assigns.threat, :status, :resolved))
      html = render_component(ThreatComponent, assigns)
      assert html =~ "Resolved"
    end

    test "displays a :not_useful status badge", %{assigns: assigns} do
      assigns = Map.put(assigns, :threat, Map.put(assigns.threat, :status, :not_useful))
      html = render_component(ThreatComponent, assigns)
      assert html =~ "Not useful"
    end

    test "shows the details as open is summary_state is set", %{assigns: assigns} do
      assigns = Map.put(assigns, :summary_state, true)
      html = render_component(ThreatComponent, assigns)
      assert html =~ "open"
    end
  end

  describe "update/2" do
    setup [:create_threat]

    test "assigns a value from a label drop down", %{socket: socket} do
      {:ok, updated_socket} =
        ThreatComponent.update(
          %{selected_label_dropdown: {nil, "status", "not_useful"}},
          socket
        )

      assert updated_socket.assigns.threat.status == :not_useful
    end

    test "assigns priority value from a label drop down", %{socket: socket} do
      {:ok, updated_socket} =
        ThreatComponent.update(
          %{selected_label_dropdown: {nil, "priority", "high"}},
          socket
        )

      assert updated_socket.assigns.threat.priority == :high
    end

    test "assigns status identified from a label drop down", %{socket: socket} do
      {:ok, updated_socket} =
        ThreatComponent.update(
          %{selected_label_dropdown: {nil, "status", "identified"}},
          socket
        )

      assert updated_socket.assigns.threat.status == :identified
    end

    test "assigns status resolved from a label drop down", %{socket: socket} do
      {:ok, updated_socket} =
        ThreatComponent.update(
          %{selected_label_dropdown: {nil, "status", "resolved"}},
          socket
        )

      assert updated_socket.assigns.threat.status == :resolved
    end

    test "assigns an empty tag", %{assigns: assigns, socket: socket} do
      {:ok, updated_socket} = ThreatComponent.update(assigns, socket)
      assert updated_socket.assigns.tag == ""
    end
  end

  describe "handle_event/3" do
    setup [:create_threat]

    test "adds a tag to the threat", %{assigns: assigns, socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, "new-tag"))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event("add_tag", %{}, socket)

      assert Enum.member?(updated_socket.assigns.threat.tags, "new-tag")
    end

    test "does nothing if tag is not set", %{assigns: assigns, socket: socket} do
      socket = Map.put(socket, :assigns, Map.delete(assigns, :tag))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event("add_tag", %{}, socket)

      assert Enum.count(updated_socket.assigns.threat.tags) ==
               Enum.count(assigns.threat.tags)
    end

    test "does nothing if tag already exists", %{assigns: assigns, socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, hd(assigns.threat.tags)))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event("add_tag", %{}, socket)

      assert Enum.count(updated_socket.assigns.threat.tags) ==
               Enum.count(assigns.threat.tags)
    end

    test "removes a tag from the threat", %{assigns: assigns, socket: socket} do
      tag = hd(assigns.threat.tags)
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, tag))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event("remove_tag", %{"tag" => tag}, socket)

      assert !Enum.member?(updated_socket.assigns.threat.tags, tag)
    end

    test "saves a comment and clears the summary_state", %{assigns: assigns, socket: socket} do
      comments = "new comments"
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, comments))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event("save_comments", %{"comments" => comments}, socket)

      assert updated_socket.assigns.threat.comments == comments
      assert updated_socket.assigns.summary_state == nil
    end

    test "sets a tag", %{assigns: assigns, socket: socket} do
      tag = "new-tag"
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, tag))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event("set_tag", %{"value" => tag}, socket)

      assert updated_socket.assigns.tag == tag
    end

    test "toggles the summary_state", %{assigns: assigns, socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(assigns, :summary_state, true))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event("toggle_summary_state", %{}, socket)

      assert updated_socket.assigns.summary_state == false
    end

    test "updates comments", %{assigns: assigns, socket: socket} do
      comments = "new comments"
      socket = Map.put(socket, :assigns, Map.put(assigns, :tag, comments))

      {:noreply, updated_socket} =
        ThreatComponent.handle_event(
          "update_comments",
          %{"comments" => comments},
          socket
        )

      assert updated_socket.assigns.threat.comments == comments
    end
  end
end
