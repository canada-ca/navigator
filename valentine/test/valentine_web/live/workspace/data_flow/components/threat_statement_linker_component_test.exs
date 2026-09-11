defmodule ValentineWeb.WorkspaceLive.DataFlow.Components.ThreatStatementLinkerComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.DataFlow.Components.ThreatStatementLinkerComponent

  defp create_component(_) do
    dfd = data_flow_diagram_fixture()
    workspace = Valentine.Composer.Workspaces.get_workspace!(dfd.workspace_id)
    node = Valentine.Composer.DataFlowDiagram.add_node(dfd.workspace_id, %{"type" => "test"})

    assigns = %{
      __changed__: %{},
      id: "threat-statement-linker-component",
      element_id: node["data"]["id"],
      element: node,
      error: nil,
      workspace_id: dfd.workspace_id,
      current_user: workspace.owner
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, node: node, socket: socket}
  end

  describe "render/1" do
    setup [:create_component]

    test "displays linked threat statements", %{assigns: assigns, node: node} do
      threat = threat_fixture()

      metadata = %{
        "id" => node["data"]["id"],
        "field" => "linked_threats",
        "value" => [threat.id]
      }

      Valentine.Composer.DataFlowDiagram.update_metadata(assigns.workspace_id, metadata)

      html = render_component(ThreatStatementLinkerComponent, assigns)
      assert html =~ Valentine.Composer.Threat.show_statement(threat)
    end

    test "do not show unlinked threat statements", %{assigns: assigns} do
      threat = threat_fixture()

      assigns = Map.put(assigns, :threats, [threat])
      html = render_component(ThreatStatementLinkerComponent, assigns)
      refute html =~ Valentine.Composer.Threat.show_statement(threat)
    end
  end

  describe "mount/1" do
    setup [:create_component]

    test "properly assigns all the right values", %{socket: socket} do
      {:ok, updated_socket} = ThreatStatementLinkerComponent.mount(socket)
      assert updated_socket.assigns.threats == []
      assert updated_socket.assigns.linked_threats == []
    end
  end

  describe "handle_event/3" do
    setup [:create_component]

    test "removes a threat from the linked threats", %{
      assigns: assigns,
      node: node,
      socket: socket
    } do
      threat = threat_fixture()

      metadata = %{
        "id" => node["data"]["id"],
        "field" => "linked_threats",
        "value" => [threat.id]
      }

      Valentine.Composer.DataFlowDiagram.update_metadata(assigns.workspace_id, metadata)

      {:noreply, updated_socket} =
        ThreatStatementLinkerComponent.handle_event("remove_threat", %{"id" => threat.id}, socket)

      assert updated_socket.assigns.linked_threats == []
    end
  end

  describe "update/2" do
    setup [:create_component]

    test "adds a threat to the linked threats", %{
      socket: socket
    } do
      threat = threat_fixture()

      {:ok, updated_socket} =
        ThreatStatementLinkerComponent.update(%{selected_item: threat}, socket)

      assert updated_socket.assigns.linked_threats == [threat]
    end

    test "sets the element, threats, and linked_threats on update", %{
      assigns: assigns,
      node: node,
      socket: socket
    } do
      linked_threat = threat_fixture()

      metadata = %{
        "id" => node["data"]["id"],
        "field" => "linked_threats",
        "value" => [linked_threat.id]
      }

      Valentine.Composer.DataFlowDiagram.update_metadata(assigns.workspace_id, metadata)

      other_threat = threat_fixture(%{workspace_id: assigns.workspace_id})

      {:ok, updated_socket} =
        ThreatStatementLinkerComponent.update(assigns, socket)

      assert updated_socket.assigns.element["data"]["id"] == assigns.element_id
      assert updated_socket.assigns.element["data"]["linked_threats"] == [linked_threat.id]
      assert updated_socket.assigns.threats == [other_threat]
      assert updated_socket.assigns.linked_threats == [linked_threat]
    end
  end
end
