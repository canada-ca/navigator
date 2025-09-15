defmodule ValentineWeb.Workspace.Mermaid do
  @moduledoc """
  Converts data flow diagrams to Mermaid.js format.

  Generates Mermaid.js state diagram syntax from Navigator's data flow diagram structure.
  """

  alias Valentine.Composer.DataFlowDiagram

  @doc """
  Generates a Mermaid.js state diagram from a workspace's data flow diagram.

  ## Examples

      iex> ValentineWeb.Workspace.Mermaid.generate_flowchart(workspace_id)
      "stateDiagram-v2\\n    [*] --> Actor\\n    Actor --> Process"
  """
  def generate_flowchart(workspace_id) do
    dfd = DataFlowDiagram.get(workspace_id)

    nodes_mermaid = generate_nodes(dfd.nodes)
    edges_mermaid = generate_edges(dfd.edges, dfd.nodes)

    ["stateDiagram-v2", nodes_mermaid, edges_mermaid]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  @doc """
  Generates node definitions for Mermaid.js state diagram.
  """
  def generate_nodes(nodes) do
    # Separate trust boundaries and regular nodes
    {trust_boundaries, regular_nodes} =
      nodes
      |> Enum.split_with(fn {_id, node} ->
        node["data"]["type"] == "trust_boundary"
      end)

    # Generate regular nodes (those not inside trust boundaries)
    standalone_nodes =
      regular_nodes
      |> Enum.filter(fn {_id, node} ->
        is_nil(node["data"]["parent"])
      end)
      |> Enum.map(fn {_id, node} -> format_node(node) end)

    # Generate trust boundaries with their nested nodes
    boundary_nodes =
      trust_boundaries
      |> Enum.map(fn {_boundary_id, boundary_node} ->
        format_trust_boundary(boundary_node, nodes)
      end)

    (standalone_nodes ++ boundary_nodes)
    |> Enum.filter(&(&1 != nil))
    |> Enum.join("\n")
  end

  @doc """
  Generates edge definitions for Mermaid.js state diagram.
  """
  def generate_edges(edges, nodes) do
    edges
    |> Enum.map(fn {_id, edge} -> format_edge(edge, nodes) end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.join("\n")
  end

  # Private functions

  defp format_node(node) do
    data = node["data"]
    id = sanitize_id(data["id"])
    label = sanitize_label(data["label"] || data["type"] || "Unknown")

    case data["type"] do
      "trust_boundary" ->
        # Trust boundaries are handled separately in format_trust_boundary
        nil

      _ ->
        "    #{id} : #{label}"
    end
  end

  defp format_trust_boundary(boundary_node, all_nodes) do
    boundary_data = boundary_node["data"]
    boundary_id = boundary_data["id"]
    boundary_label = sanitize_state_name(boundary_data["label"] || "Trust_Boundary")

    # Find all nodes that belong to this trust boundary
    child_nodes =
      all_nodes
      |> Enum.filter(fn {_id, node} ->
        node["data"]["parent"] == boundary_id && node["data"]["type"] != "trust_boundary"
      end)
      |> Enum.map(fn {_id, node} ->
        data = node["data"]
        id = sanitize_id(data["id"])
        label = sanitize_label(data["label"] || data["type"] || "Unknown")
        "        #{id} : #{label}"
      end)

    if Enum.empty?(child_nodes) do
      # Empty trust boundary - still create the state but with no content
      "    state #{boundary_label} {\n    }"
    else
      child_content = Enum.join(child_nodes, "\n")
      "    state #{boundary_label} {\n#{child_content}\n    }"
    end
  end

  defp format_edge(edge, nodes) do
    data = edge["data"]
    source_id = sanitize_id(data["source"])
    target_id = sanitize_id(data["target"])
    label = sanitize_label(data["label"] || "")

    # Check if source and target nodes exist
    source_exists = Map.has_key?(nodes, data["source"])
    target_exists = Map.has_key?(nodes, data["target"])

    if source_exists && target_exists do
      if label != "" do
        "    #{source_id} --> #{target_id} : #{label}"
      else
        "    #{source_id} --> #{target_id}"
      end
    else
      nil
    end
  end

  defp sanitize_id(id) when is_binary(id) do
    id
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
    |> String.replace(~r/^(\d)/, "_\\1")
  end

  defp sanitize_id(_), do: "unknown"

  # For state names, we want to allow more characters but still keep it valid
  defp sanitize_state_name(name) when is_binary(name) do
    name
    |> String.replace(~r/[^a-zA-Z0-9_\s]/, "_")
    |> String.replace(~r/\s+/, "_")
    |> String.replace(~r/^(\d)/, "_\\1")
  end

  defp sanitize_state_name(_), do: "Unknown"

  defp sanitize_label(label) when is_binary(label) do
    label
    |> String.replace("\"", "&quot;")
    |> String.replace("[", "&#91;")
    |> String.replace("]", "&#93;")
    |> String.replace("(", "&#40;")
    |> String.replace(")", "&#41;")
  end

  defp sanitize_label(_), do: "Unknown"
end
