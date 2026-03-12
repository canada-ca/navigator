defmodule ValentineWeb.WorkspaceLive.Components.DataFlowMetadataComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest

  alias ValentineWeb.WorkspaceLive.Components.DataFlowMetadataComponent

  import Valentine.ComposerFixtures
  alias Valentine.Composer.DataFlowDiagram

  setup do
    dfd = data_flow_diagram_fixture()
    node = DataFlowDiagram.add_node(dfd.workspace_id, %{"type" => "test"})

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        element_id: node["data"]["id"],
        workspace_id: dfd.workspace_id
      }
    }

    %{dfd: dfd, node: node, socket: socket, workspace_id: dfd.workspace_id}
  end

  test "renders properly", %{node: node, socket: socket} do
    html = render_component(DataFlowMetadataComponent, socket.assigns)
    assert html =~ node["data"]["id"]
  end

  describe "update/2" do
    test "updates the assigns with the selected node based on element_id", %{
      node: node,
      socket: socket
    } do
      {:ok, socket} = DataFlowMetadataComponent.update(socket.assigns, socket)
      assert socket.assigns.element == node
      assert socket.assigns.threats == []
    end

    test "updates the assigns with the selected node based on element_id and loads linked_threats",
         %{
           node: node,
           socket: socket
         } do
      threat = threat_fixture()

      metadata = %{
        "id" => node["data"]["id"],
        "field" => "linked_threats",
        "value" => [threat.id]
      }

      DataFlowDiagram.update_metadata(socket.assigns.workspace_id, metadata)

      {:ok, socket} = DataFlowMetadataComponent.update(socket.assigns, socket)
      assert socket.assigns.element["data"]["id"] == node["data"]["id"]
      assert socket.assigns.threats == [threat]
    end

    test "updates the assigns for imported nodes whose ids do not use the node prefix", %{
      dfd: dfd,
      socket: socket
    } do
      imported_node = %{
        "data" => %{
          "id" => "api",
          "data_tags" => [],
          "description" => "API service",
          "label" => "API",
          "linked_threats" => [],
          "out_of_scope" => "false",
          "parent" => nil,
          "security_tags" => [],
          "technology_tags" => [],
          "type" => "process"
        },
        "grabbable" => "true",
        "position" => %{"x" => 100, "y" => 100}
      }

      dfd
      |> Map.update!(:nodes, &Map.put(&1, "api", imported_node))
      |> DataFlowDiagram.put()

      assigns = %{socket.assigns | element_id: "api"}

      {:ok, socket} = DataFlowMetadataComponent.update(assigns, socket)
      assert socket.assigns.element == imported_node
      assert socket.assigns.threats == []
    end
  end
end
