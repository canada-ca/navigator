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
    nodes
    |> Enum.map(fn {_id, node} -> format_node(node) end)
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
      "actor" ->
        "    #{id} : #{label}"

      "process" ->
        "    #{id} : #{label}"

      "datastore" ->
        "    #{id} : #{label}"

      "trust_boundary" ->
        "    state #{id} {\n        #{id}_inner : #{label}\n    }"

      _ ->
        "    #{id} : #{label}"
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
