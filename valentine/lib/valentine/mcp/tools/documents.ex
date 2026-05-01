defmodule Valentine.MCP.Tools.Documents do
  import Valentine.MCP.ToolHelpers

  alias Valentine.Composer
  alias Valentine.Composer.DataFlowDiagram
  alias ValentineWeb.Workspace.Mermaid

  @node_types ["actor", "process", "datastore", "trust_boundary"]

  def get_application_information(_args, api_key) do
    workspace = Composer.get_workspace!(api_key.workspace_id, [:application_information])
    ok_json(document_map(workspace.application_information))
  end

  def update_application_information(%{"content" => content}, api_key) do
    workspace = Composer.get_workspace!(api_key.workspace_id, [:application_information])

    result =
      case workspace.application_information do
        nil ->
          Composer.create_application_information(%{
            "workspace_id" => workspace.id,
            "content" => content
          })

        doc ->
          Composer.update_application_information(doc, %{"content" => content})
      end

    Composer.ApplicationInformation.flush_cache(workspace.id)
    document_result(result)
  end

  def get_architecture(_args, api_key) do
    workspace = Composer.get_workspace!(api_key.workspace_id, [:architecture])
    ok_json(document_map(workspace.architecture))
  end

  def update_architecture(%{"content" => content}, api_key) do
    workspace = Composer.get_workspace!(api_key.workspace_id, [:architecture])

    result =
      case workspace.architecture do
        nil ->
          Composer.create_architecture(%{"workspace_id" => workspace.id, "content" => content})

        doc ->
          Composer.update_architecture(doc, %{"content" => content})
      end

    Composer.Architecture.flush_cache(workspace.id)
    document_result(result)
  end

  def get_data_flow_diagram(_args, api_key) do
    api_key.workspace_id
    |> DataFlowDiagram.get()
    |> dfd_map()
    |> ok_json()
  end

  def update_data_flow_diagram(args, api_key) do
    dfd = DataFlowDiagram.get(api_key.workspace_id)
    attrs = Map.take(args, ["nodes", "edges", "raw_image"])
    {attrs, normalization_hints} = normalize_dfd_attrs(attrs)

    case validate_dfd_attrs(attrs, dfd) do
      :ok ->
        case Composer.update_data_flow_diagram(dfd, attrs) do
          {:ok, dfd} ->
            DataFlowDiagram.put(dfd)
            ok_json(Map.put(dfd_map(dfd), :validation_hints, dfd_hints(dfd, normalization_hints)))

          {:error, changeset} ->
            tool_error(Jason.encode!(format_changeset_errors(changeset)))
        end

      {:error, message} ->
        tool_error(message)
    end
  end

  def export_dfd_mermaid(_args, api_key) do
    api_key.workspace_id
    |> Mermaid.generate_flowchart()
    |> ok_text()
  end

  defp document_result({:ok, document}), do: ok_json(document_map(document))

  defp document_result({:error, changeset}),
    do: tool_error(Jason.encode!(format_error(changeset)))

  defp document_map(nil), do: %{id: nil, workspace_id: nil, content: nil}

  defp document_map(document) do
    %{
      id: document.id,
      workspace_id: document.workspace_id,
      content: document.content,
      inserted_at: document.inserted_at,
      updated_at: document.updated_at
    }
  end

  defp dfd_map(dfd) do
    %{
      id: dfd.id,
      workspace_id: dfd.workspace_id,
      nodes: dfd.nodes,
      edges: dfd.edges,
      raw_image: dfd.raw_image,
      inserted_at: dfd.inserted_at,
      updated_at: dfd.updated_at
    }
  end

  defp normalize_dfd_attrs(%{"nodes" => nodes} = attrs) when is_map(nodes) do
    {nodes, positioned_node_ids} =
      nodes
      |> Map.keys()
      |> Enum.sort()
      |> Enum.with_index()
      |> Enum.reduce({nodes, []}, fn {id, index}, {acc, positioned_node_ids} ->
        node = Map.get(acc, id)

        if is_map(node) && !valid_position?(Map.get(node, "position")) do
          {
            Map.put(acc, id, Map.put(node, "position", auto_position(index))),
            [id | positioned_node_ids]
          }
        else
          {acc, positioned_node_ids}
        end
      end)

    {Map.put(attrs, "nodes", nodes), %{auto_positioned_nodes: Enum.reverse(positioned_node_ids)}}
  end

  defp normalize_dfd_attrs(attrs), do: {attrs, %{auto_positioned_nodes: []}}

  defp validate_dfd_attrs(attrs, dfd) do
    effective_nodes = Map.get(attrs, "nodes", dfd.nodes)
    effective_edges = Map.get(attrs, "edges", dfd.edges)

    with :ok <- validate_nodes(effective_nodes),
         :ok <- validate_edges(effective_edges, effective_nodes),
         :ok <- validate_raw_image(attrs) do
      :ok
    end
  end

  defp validate_nodes(nodes) when is_map(nodes) do
    Enum.reduce_while(nodes, :ok, fn {id, node}, _acc ->
      case validate_node(id, node) do
        :ok -> {:cont, :ok}
        {:error, message} -> {:halt, {:error, message}}
      end
    end)
  end

  defp validate_nodes(_nodes), do: {:error, "DFD nodes must be an object"}

  defp validate_node(id, %{"data" => %{} = data} = node) when is_binary(id) do
    cond do
      Map.get(data, "id") != id ->
        {:error, "DFD node #{id} data.id must match the node key"}

      !is_binary(Map.get(data, "label")) ->
        {:error, "DFD node #{id} must include a string data.label"}

      Map.get(data, "type") not in @node_types ->
        {:error, "DFD node #{id} has an unsupported data.type"}

      !valid_position?(Map.get(node, "position")) ->
        {:error, "DFD node #{id} must include position.x and position.y numbers"}

      true ->
        :ok
    end
  end

  defp validate_node(id, _node) when is_binary(id),
    do: {:error, "DFD node #{id} must include a data object"}

  defp validate_node(_id, _node), do: {:error, "DFD node keys must be strings"}

  defp validate_edges(edges, nodes) when is_map(edges) do
    Enum.reduce_while(edges, :ok, fn {id, edge}, _acc ->
      case validate_edge(id, edge, nodes) do
        :ok -> {:cont, :ok}
        {:error, message} -> {:halt, {:error, message}}
      end
    end)
  end

  defp validate_edges(_edges, _nodes), do: {:error, "DFD edges must be an object"}

  defp validate_edge(id, %{"data" => %{} = data}, nodes) when is_binary(id) do
    source = Map.get(data, "source")
    target = Map.get(data, "target")

    cond do
      Map.get(data, "id") != id ->
        {:error, "DFD edge #{id} data.id must match the edge key"}

      !is_binary(source) ->
        {:error, "DFD edge #{id} must include a string data.source"}

      !is_binary(target) ->
        {:error, "DFD edge #{id} must include a string data.target"}

      !Map.has_key?(nodes, source) ->
        {:error, "DFD edge #{id} references an unknown source node"}

      !Map.has_key?(nodes, target) ->
        {:error, "DFD edge #{id} references an unknown target node"}

      true ->
        :ok
    end
  end

  defp validate_edge(id, _edge, _nodes) when is_binary(id),
    do: {:error, "DFD edge #{id} must include a data object"}

  defp validate_edge(_id, _edge, _nodes), do: {:error, "DFD edge keys must be strings"}

  defp validate_raw_image(%{"raw_image" => raw_image})
       when not is_binary(raw_image) and not is_nil(raw_image),
       do: {:error, "DFD raw_image must be a string"}

  defp validate_raw_image(_attrs), do: :ok

  defp valid_position?(%{"x" => x, "y" => y}) when is_number(x) and is_number(y), do: true
  defp valid_position?(_position), do: false

  defp auto_position(index) do
    %{
      "x" => rem(index, 4) * 260,
      "y" => div(index, 4) * 180
    }
  end

  defp dfd_hints(dfd, normalization_hints) do
    []
    |> maybe_add_auto_position_hint(
      normalization_hints.auto_positioned_nodes,
      map_size(dfd.nodes)
    )
    |> maybe_add_orphan_trust_boundary_hint(dfd.nodes)
    |> maybe_add_long_label_hint(dfd.nodes)
    |> maybe_add_overlapping_position_hint(dfd.nodes)
    |> Enum.reverse()
  end

  defp maybe_add_auto_position_hint(hints, [], _node_count), do: hints

  defp maybe_add_auto_position_hint(hints, node_ids, node_count) do
    [
      %{
        code: "auto_positioned_nodes",
        severity: "warning",
        message:
          "Some DFD nodes did not include usable position.x and position.y values, so Navigator assigned grid positions to avoid collapsed rendering.",
        node_ids: node_ids,
        count: length(node_ids),
        total_nodes: node_count
      }
      | hints
    ]
  end

  defp maybe_add_orphan_trust_boundary_hint(hints, nodes) do
    orphan_ids =
      nodes
      |> Enum.filter(fn {_id, node} -> get_in(node, ["data", "type"]) == "trust_boundary" end)
      |> Enum.reject(fn {id, _node} -> trust_boundary_has_children?(nodes, id) end)
      |> Enum.map(fn {id, _node} -> id end)

    case orphan_ids do
      [] ->
        hints

      _ ->
        [
          %{
            code: "orphan_trust_boundaries",
            severity: "warning",
            message:
              "Trust boundaries render as useful containers only when child nodes set data.parent to the boundary node ID.",
            node_ids: orphan_ids
          }
          | hints
        ]
    end
  end

  defp trust_boundary_has_children?(nodes, boundary_id) do
    Enum.any?(nodes, fn {_id, node} -> get_in(node, ["data", "parent"]) == boundary_id end)
  end

  defp maybe_add_long_label_hint(hints, nodes) do
    long_label_ids =
      nodes
      |> Enum.filter(fn {_id, node} ->
        label = get_in(node, ["data", "label"])
        is_binary(label) && String.length(label) > 60
      end)
      |> Enum.map(fn {id, _node} -> id end)

    case long_label_ids do
      [] ->
        hints

      _ ->
        [
          %{
            code: "long_labels",
            severity: "warning",
            message:
              "Long DFD labels can overlap nearby nodes; prefer concise labels and details in data.description.",
            node_ids: long_label_ids
          }
          | hints
        ]
    end
  end

  defp maybe_add_overlapping_position_hint(hints, nodes) do
    overlapping_ids =
      nodes
      |> Enum.group_by(fn {_id, node} ->
        position = Map.get(node, "position")
        {Map.get(position, "x"), Map.get(position, "y")}
      end)
      |> Enum.filter(fn {_position, grouped_nodes} -> length(grouped_nodes) > 1 end)
      |> Enum.flat_map(fn {_position, grouped_nodes} ->
        Enum.map(grouped_nodes, fn {id, _node} -> id end)
      end)
      |> Enum.sort()

    case overlapping_ids do
      [] ->
        hints

      _ ->
        [
          %{
            code: "overlapping_positions",
            severity: "warning",
            message: "Multiple DFD nodes share the same position and may visually overlap.",
            node_ids: overlapping_ids
          }
          | hints
        ]
    end
  end
end
