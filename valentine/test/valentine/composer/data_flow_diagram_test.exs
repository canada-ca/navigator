defmodule Valentine.Composer.DataFlowDiagramTest do
  use ValentineWeb.ConnCase

  alias Valentine.Composer.DataFlowDiagram
  import Valentine.ComposerFixtures

  setup do
    workspace = workspace_fixture()
    {:ok, workspace_id: workspace.id}
  end

  test "new/1 creates a new DataFlowDiagram", %{workspace_id: workspace_id} do
    dfd = DataFlowDiagram.new(workspace_id)
    assert %DataFlowDiagram{id: _, workspace_id: ^workspace_id, nodes: %{}, edges: %{}} = dfd
  end

  test "add_node/2 adds a new node", %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    assert node["data"]["type"] == "test"
    assert node["data"]["label"] == "Test"
    assert node["data"]["parent"] == nil
    assert node["grabbable"] == "true"
    assert node["position"]["x"] <= 400
    assert node["position"]["y"] <= 400
  end

  test "add_node/2 adds a new node to a parent node if the selected node is a trust boundary", %{
    workspace_id: workspace_id
  } do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "trust_boundary"})

    node2 =
      DataFlowDiagram.add_node(workspace_id, %{
        "type" => "test",
        "selected_elements" => %{"nodes" => %{"#{node["data"]["id"]}" => node}}
      })

    assert node2["data"]["parent"] == node["data"]["id"]
  end

  test "add_node/2 does not add a new node to a parent node if more than one node is selected", %{
    workspace_id: workspace_id
  } do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})

    node3 =
      DataFlowDiagram.add_node(workspace_id, %{
        "type" => "test",
        "selected_elements" => %{
          "nodes" => %{"#{node1["data"]["id"]}" => node1, "#{node2["data"]["id"]}" => node2}
        }
      })

    assert node3["data"]["parent"] == nil
  end

  test "clear_dfd/2 clears the DataFlowDiagram", %{workspace_id: workspace_id} do
    DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    DataFlowDiagram.clear_dfd(workspace_id, %{})
    dfd = DataFlowDiagram.get(workspace_id)
    assert Kernel.map_size(dfd.nodes) == 0
    assert Kernel.map_size(dfd.edges) == 0
  end

  test "ehcomplete/2 adds a new edge", %{workspace_id: workspace_id} do
    edge = %{"id" => "edge-1", "source" => "node-1", "target" => "node-2"}
    new_edge = DataFlowDiagram.ehcomplete(workspace_id, %{"edge" => edge})
    assert new_edge["data"]["id"] == edge["id"]
    assert new_edge["data"]["source"] == edge["source"]
    assert new_edge["data"]["target"] == edge["target"]
  end

  test "fit_view/2 returns nil", %{workspace_id: workspace_id} do
    assert DataFlowDiagram.fit_view(workspace_id, %{}) == nil
  end

  test "free/2 sets node grabbable to true", %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    DataFlowDiagram.grab(workspace_id, %{"node" => %{"id" => node["data"]["id"]}})
    updated_node = DataFlowDiagram.free(workspace_id, %{"node" => %{"id" => node["data"]["id"]}})
    assert updated_node["grabbable"] == "true"
  end

  test "get/2 returns the DataFlowDiagram", %{workspace_id: workspace_id} do
    dfd = DataFlowDiagram.get(workspace_id)
    assert %DataFlowDiagram{id: _, workspace_id: ^workspace_id, nodes: %{}, edges: %{}} = dfd
  end

  test "get/2 returns the DataFlowDiagram skipping the cache", %{workspace_id: workspace_id} do
    DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    dfd = DataFlowDiagram.get(workspace_id, false)
    assert %DataFlowDiagram{id: _, workspace_id: ^workspace_id, nodes: %{}, edges: %{}} = dfd
  end

  test "grab/2 sets node grabbable to false", %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    updated_node = DataFlowDiagram.grab(workspace_id, %{"node" => %{"id" => node["data"]["id"]}})
    assert updated_node["grabbable"] == "false"
  end

  test "group_nodes/2 returns and empty response if no nodes are selected", %{
    workspace_id: workspace_id
  } do
    assert DataFlowDiagram.group_nodes(workspace_id, %{"selected_elements" => %{"nodes" => %{}}}) ==
             %{node: %{}, children: []}
  end

  test "group_nodes/2 groups selected nodes", %{workspace_id: workspace_id} do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    selected_elements = %{"nodes" => %{"node-1" => node1, "node-2" => node2}}

    grouped_nodes =
      DataFlowDiagram.group_nodes(workspace_id, %{"selected_elements" => selected_elements})

    assert grouped_nodes[:node]["data"]["type"] == "trust_boundary"
    assert grouped_nodes[:children] == Map.keys(selected_elements["nodes"])
  end

  test "merge_group/2 returns an error if none of the selected nodes are a trust boundary", %{
    workspace_id: workspace_id
  } do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    nodes = %{}
    nodes = Map.put(nodes, node1["data"]["id"], node1["data"]["label"])
    nodes = Map.put(nodes, node2["data"]["id"], node2["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    assert DataFlowDiagram.merge_group(workspace_id, %{"selected_elements" => selected_elements}) ==
             {:error, "Only trust boundaries can be merged"}
  end

  test "merge_group/2 merges selected nodes into a trust boundary", %{workspace_id: workspace_id} do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "trust_boundary"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "trust_boundary"})
    nodes = %{}
    nodes = Map.put(nodes, node1["data"]["id"], node1["data"]["label"])
    nodes = Map.put(nodes, node2["data"]["id"], node2["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    grouped_nodes =
      DataFlowDiagram.group_nodes(workspace_id, %{"selected_elements" => selected_elements})

    node3 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    nodes = %{}
    nodes = Map.put(nodes, node3["data"]["id"], node3["data"]["label"])

    nodes =
      Map.put(nodes, grouped_nodes[:node]["data"]["id"], grouped_nodes[:node]["data"]["label"])

    selected_elements = %{"nodes" => nodes}

    merged_group =
      DataFlowDiagram.merge_group(workspace_id, %{"selected_elements" => selected_elements})

    assert merged_group[:node] == grouped_nodes[:node]["data"]["id"]
    assert merged_group[:children] == [node3["data"]["id"]]
    assert merged_group[:purge] == []
  end

  test "merge_group/2 merges two selected trust boundaries", %{workspace_id: workspace_id} do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    nodes = %{}
    nodes = Map.put(nodes, node1["data"]["id"], node1["data"]["label"])
    nodes = Map.put(nodes, node2["data"]["id"], node2["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    group1 =
      DataFlowDiagram.group_nodes(workspace_id, %{"selected_elements" => selected_elements})

    node3 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node4 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    nodes = %{}
    nodes = Map.put(nodes, node3["data"]["id"], node3["data"]["label"])
    nodes = Map.put(nodes, node4["data"]["id"], node4["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    group2 =
      DataFlowDiagram.group_nodes(workspace_id, %{"selected_elements" => selected_elements})

    nodes = %{}
    nodes = Map.put(nodes, group1[:node]["data"]["id"], group1[:node]["data"]["label"])
    nodes = Map.put(nodes, group2[:node]["data"]["id"], group2[:node]["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    merged_group =
      DataFlowDiagram.merge_group(workspace_id, %{"selected_elements" => selected_elements})

    assert merged_group[:node] == group1[:node]["data"]["id"] || group2[:node]["data"]["id"]

    assert merged_group[:children] == [node1["data"]["id"], node2["data"]["id"]] ||
             [node3["data"]["id"], node4["data"]["id"]]

    assert merged_group[:purge] == [group2[:node]["data"]["id"]] || [group1[:node]["data"]["id"]]
  end

  test "position/2 updates node position", %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    new_position = %{"x" => 100, "y" => 200}

    updated_node =
      DataFlowDiagram.position(workspace_id, %{
        "node" => %{"id" => node["data"]["id"], "position" => new_position}
      })

    assert updated_node["position"]["x"] == 100
    assert updated_node["position"]["y"] == 200
  end

  test "remove_elements/2 deletes selected nodes and edges", %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    edge = %{"id" => "edge-1", "source" => "node-1", "target" => "node-2"}
    DataFlowDiagram.ehcomplete(workspace_id, %{"edge" => edge})

    selected_elements = %{"nodes" => %{"node-1" => node}, "edges" => %{"edge-1" => edge}}

    removed_elements =
      DataFlowDiagram.remove_elements(workspace_id, %{"selected_elements" => selected_elements})

    assert removed_elements["nodes"] == %{"node-1" => node}
    assert removed_elements["edges"] == %{"edge-1" => edge}

    dfd = DataFlowDiagram.get(workspace_id)
    assert Kernel.map_size(dfd.nodes) == 1
    assert Kernel.map_size(dfd.edges) == 0
  end

  test "remove_elements/2 deletes nodes and edges inside a group", %{workspace_id: workspace_id} do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    edge = %{"id" => "edge-1", "source" => node1["data"]["id"], "target" => node2["data"]["id"]}
    DataFlowDiagram.ehcomplete(workspace_id, %{"edge" => edge})
    nodes = %{}
    nodes = Map.put(nodes, node1["data"]["id"], node1["data"]["label"])
    nodes = Map.put(nodes, node2["data"]["id"], node2["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    grouped_nodes =
      DataFlowDiagram.group_nodes(workspace_id, %{"selected_elements" => selected_elements})

    nodes = %{}

    nodes =
      Map.put(nodes, grouped_nodes[:node]["data"]["id"], grouped_nodes[:node]["data"]["label"])

    selected_elements = %{"nodes" => nodes, "edges" => %{}}

    DataFlowDiagram.remove_elements(workspace_id, %{"selected_elements" => selected_elements})

    dfd = DataFlowDiagram.get(workspace_id)
    assert Kernel.map_size(dfd.nodes) == 0
    assert Kernel.map_size(dfd.edges) == 0
  end

  test "remove_group/2 returns an error if only one node is selected", %{
    workspace_id: workspace_id
  } do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    nodes = %{}
    nodes = Map.put(nodes, node1["data"]["id"], node1["data"]["label"])
    nodes = Map.put(nodes, node2["data"]["id"], node2["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    assert DataFlowDiagram.remove_group(workspace_id, %{"selected_elements" => selected_elements}) ==
             {:error, "Only one trust boundaries can be removed at a time"}
  end

  test "remove_group/2 returns an error if something other than a trust boundary is removed", %{
    workspace_id: workspace_id
  } do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    nodes = %{}
    nodes = Map.put(nodes, node1["data"]["id"], node1["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    assert DataFlowDiagram.remove_group(workspace_id, %{"selected_elements" => selected_elements}) ==
             {:error, "Only trust boundaries can be removed"}
  end

  test "remove_group/2 removes a parent from a set of nodes and removes the parent", %{
    workspace_id: workspace_id
  } do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    nodes = %{}
    nodes = Map.put(nodes, node1["data"]["id"], node1["data"]["label"])
    nodes = Map.put(nodes, node2["data"]["id"], node2["data"]["label"])
    selected_elements = %{"nodes" => nodes}

    grouped_nodes =
      DataFlowDiagram.group_nodes(workspace_id, %{"selected_elements" => selected_elements})

    nodes = %{}

    nodes =
      Map.put(nodes, grouped_nodes[:node]["data"]["id"], grouped_nodes[:node]["data"]["label"])

    selected_elements = %{"nodes" => nodes}

    DataFlowDiagram.remove_group(workspace_id, %{"selected_elements" => selected_elements})

    dfd = DataFlowDiagram.get(workspace_id)
    assert Kernel.map_size(dfd.nodes) == 2
    assert Kernel.map_size(dfd.edges) == 0
    refute Map.has_key?(dfd.nodes, grouped_nodes[:node]["data"]["id"])
  end

  test "remove_linked_threats/2 removes linked threats from a node", %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    metadata = %{"id" => node["data"]["id"], "field" => "linked_threats", "value" => ["T1"]}
    DataFlowDiagram.update_metadata(workspace_id, metadata)

    DataFlowDiagram.remove_linked_threats(workspace_id, "T1")

    dfd = DataFlowDiagram.get(workspace_id)

    assert dfd.nodes[node["data"]["id"]]["data"]["linked_threats"] == []
  end

  test "remove_linked_threats/2 removes linked threats from edge", %{workspace_id: workspace_id} do
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    edge = %{"id" => "edge-1", "source" => node1["data"]["id"], "target" => node2["data"]["id"]}
    DataFlowDiagram.ehcomplete(workspace_id, %{"edge" => edge})
    metadata = %{"id" => edge["id"], "field" => "linked_threats", "value" => ["T1"]}
    DataFlowDiagram.update_metadata(workspace_id, metadata)

    DataFlowDiagram.remove_linked_threats(workspace_id, "T1")

    dfd = DataFlowDiagram.get(workspace_id)

    assert dfd.edges[edge["id"]]["data"]["linked_threats"] == []
  end

  test "to_json", %{workspace_id: workspace_id} do
    assert DataFlowDiagram.to_json(workspace_id) == "{\"nodes\":{},\"edges\":{}}"
  end

  test "update_metadata/2 updates node metadata", %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    new_metadata = %{"id" => node["data"]["id"], "field" => "label", "value" => "New Label"}

    resp =
      DataFlowDiagram.update_metadata(
        workspace_id,
        new_metadata
      )

    assert resp == %{"id" => node["data"]["id"], "field" => "label", "value" => "New Label"}

    dfd = DataFlowDiagram.get(workspace_id)
    updated_node = Map.get(dfd.nodes, node["data"]["id"])

    assert updated_node["data"]["label"] == "New Label"
  end

  test "update_metadata/2 updates node metadata with a boolean value if value is missing (ex: checkbox boolean)",
       %{workspace_id: workspace_id} do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    new_metadata = %{"id" => node["data"]["id"], "field" => "checked"}

    resp =
      DataFlowDiagram.update_metadata(
        workspace_id,
        new_metadata
      )

    assert resp == %{"id" => node["data"]["id"], "field" => "checked", "value" => "false"}

    dfd = DataFlowDiagram.get(workspace_id)
    updated_node = Map.get(dfd.nodes, node["data"]["id"])

    assert updated_node["data"]["checked"] == "false"
  end

  test "update_metadata/2 updates node metadata with multiselect checks", %{
    workspace_id: workspace_id
  } do
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    new_metadata = %{"id" => node["data"]["id"], "field" => "data_tags", "checked" => "a"}

    resp =
      DataFlowDiagram.update_metadata(
        workspace_id,
        new_metadata
      )

    assert resp == %{"id" => node["data"]["id"], "field" => "data_tags", "value" => ["a"]}

    dfd = DataFlowDiagram.get(workspace_id)
    updated_node = Map.get(dfd.nodes, node["data"]["id"])

    assert updated_node["data"]["data_tags"] == ["a"]

    # Test removing a value

    DataFlowDiagram.update_metadata(
      workspace_id,
      new_metadata
    )

    dfd = DataFlowDiagram.get(workspace_id)
    updated_node = Map.get(dfd.nodes, node["data"]["id"])

    assert updated_node["data"]["data_tags"] == []
  end

  test "zoom_in/2 returns nil", %{workspace_id: workspace_id} do
    assert DataFlowDiagram.zoom_in(workspace_id, %{}) == nil
  end

  test "zoom_out/2 returns nil", %{workspace_id: workspace_id} do
    assert DataFlowDiagram.zoom_out(workspace_id, %{}) == nil
  end

  # History functionality tests
  test "can_undo?/1 returns false when no history exists", %{workspace_id: workspace_id} do
    refute DataFlowDiagram.can_undo?(workspace_id)
  end

  test "can_redo?/1 returns false when no future states exist", %{workspace_id: workspace_id} do
    refute DataFlowDiagram.can_redo?(workspace_id)
  end

  test "push_to_history/1 adds current state to history", %{workspace_id: workspace_id} do
    DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})
    DataFlowDiagram.push_to_history(workspace_id)

    assert DataFlowDiagram.can_undo?(workspace_id)
  end

  test "undo/2 returns error when no history exists", %{workspace_id: workspace_id} do
    assert DataFlowDiagram.undo(workspace_id, %{}) == {:error, "No states to undo"}
  end

  test "redo/2 returns error when no future states exist", %{workspace_id: workspace_id} do
    assert DataFlowDiagram.redo(workspace_id, %{}) == {:error, "No states to redo"}
  end

  test "undo/2 restores previous state", %{workspace_id: workspace_id} do
    # Add initial node and save to history
    DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})

    # Add another node
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test2"})

    # Undo should restore state before second node
    result = DataFlowDiagram.undo(workspace_id, %{})

    refute result == {:error, "No states to undo"}

    # Check that the second node is no longer in the diagram
    dfd = DataFlowDiagram.get(workspace_id)
    refute Map.has_key?(dfd.nodes, node2["data"]["id"])

    # Should now be able to redo
    assert DataFlowDiagram.can_redo?(workspace_id)
  end

  test "redo/2 restores future state", %{workspace_id: workspace_id} do
    # Add initial node
    node1 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})

    # Add another node
    node2 = DataFlowDiagram.add_node(workspace_id, %{"type" => "test2"})

    # Undo
    DataFlowDiagram.undo(workspace_id, %{})

    # Redo should restore the second node
    result = DataFlowDiagram.redo(workspace_id, %{})

    refute result == {:error, "No states to redo"}

    # Check that both nodes are back
    dfd = DataFlowDiagram.get(workspace_id)
    assert Map.has_key?(dfd.nodes, node1["data"]["id"])
    assert Map.has_key?(dfd.nodes, node2["data"]["id"])

    # Should not be able to redo anymore
    refute DataFlowDiagram.can_redo?(workspace_id)
  end

  test "new changes after undo clear future states", %{workspace_id: workspace_id} do
    # Add initial node
    DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})

    # Add another node
    DataFlowDiagram.add_node(workspace_id, %{"type" => "test2"})

    # Undo
    DataFlowDiagram.undo(workspace_id, %{})

    # Should be able to redo
    assert DataFlowDiagram.can_redo?(workspace_id)

    # Add a different node (this should clear future states)
    DataFlowDiagram.add_node(workspace_id, %{"type" => "test3"})

    # Should no longer be able to redo
    refute DataFlowDiagram.can_redo?(workspace_id)
  end

  test "history is limited to maximum size", %{workspace_id: workspace_id} do
    # Add more nodes than the history limit
    for i <- 1..55 do
      DataFlowDiagram.add_node(workspace_id, %{"type" => "test#{i}"})
    end

    {history_stack, _} = DataFlowDiagram.get_history_stacks(workspace_id)

    # History should be limited to 50 entries
    assert length(history_stack) <= 50
  end

  test "drag operation creates only one history entry", %{workspace_id: workspace_id} do
    # Add a node
    node = DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})

    # Simulate starting a drag (grab)
    DataFlowDiagram.grab(workspace_id, %{"node" => %{"id" => node["data"]["id"]}})

    # Get history stack after grab
    {history_after_grab, _} = DataFlowDiagram.get_history_stacks(workspace_id)
    grab_history_count = length(history_after_grab)

    # Simulate multiple position changes during drag
    DataFlowDiagram.position(workspace_id, %{
      "node" => %{"id" => node["data"]["id"], "position" => %{"x" => 10, "y" => 10}}
    })

    DataFlowDiagram.position(workspace_id, %{
      "node" => %{"id" => node["data"]["id"], "position" => %{"x" => 20, "y" => 20}}
    })

    DataFlowDiagram.position(workspace_id, %{
      "node" => %{"id" => node["data"]["id"], "position" => %{"x" => 30, "y" => 30}}
    })

    # Simulate ending drag (free)
    DataFlowDiagram.free(workspace_id, %{"node" => %{"id" => node["data"]["id"]}})

    # Get final history stack
    {final_history, _} = DataFlowDiagram.get_history_stacks(workspace_id)
    final_history_count = length(final_history)

    # Should have only one additional history entry from the grab operation
    # Position changes should not add to history, and free should not add to history
    assert final_history_count == grab_history_count
  end
end
