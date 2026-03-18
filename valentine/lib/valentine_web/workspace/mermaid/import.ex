defmodule ValentineWeb.Workspace.Mermaid.Import do
  @moduledoc """
  Parses supported Mermaid syntax into Navigator data flow diagram structures.
  """

  alias Phoenix.Naming

  @unsupported_directive_pattern ~r/^(classDef|class|style|linkStyle|direction)\b/
  @state_header_pattern ~r/^stateDiagram(?:-v2)?(?:\s+.*)?$/i
  @flow_header_pattern ~r/^(?:flowchart|graph)(?:\s+\w+)?$/i
  @edge_pattern ~r/^(?<left>.+?)\s*(?<arrow>-->|---|-.->|==>)\s*(?:\|(?<label>[^|]+)\|\s*)?(?<right>.+)$/
  @state_edge_pattern ~r/^(?<source>[A-Za-z0-9_.-]+|\[\*\])\s*-->\s*(?<target>[A-Za-z0-9_.-]+|\[\*\])(?:\s*:\s*(?<label>.+))?$/
  @state_node_pattern ~r/^(?<ref>[A-Za-z0-9_.-]+)\s*:\s*(?<label>.+)$/

  def preview(source) when is_binary(source) do
    with {:ok, diagram_type, lines} <- normalize_source(source),
         {:ok, state} <- parse_lines(diagram_type, lines) do
      {:ok, build_preview(state)}
    end
  end

  def preview(_), do: {:error, "Mermaid source is empty"}

  defp normalize_source(source) do
    lines =
      source
      |> String.split(~r/\R/)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "%%")))

    case lines do
      [] ->
        {:error, "Mermaid source is empty"}

      [header | rest] ->
        cond do
          Regex.match?(@state_header_pattern, header) -> {:ok, :state, rest}
          Regex.match?(@flow_header_pattern, header) -> {:ok, :flowchart, rest}
          true -> {:error, "Unsupported Mermaid diagram type"}
        end
    end
  end

  defp parse_lines(diagram_type, lines) do
    state = %{
      diagram_type: diagram_type,
      nodes: %{},
      edges: %{},
      ref_map: %{},
      boundary_stack: [],
      next_node_index: 1,
      next_edge_index: 1,
      inferred_node_count: 0,
      unsupported_lines: [],
      implicit_boundary_count: 0
    }

    lines
    |> Enum.reduce_while({:ok, state}, fn line, {:ok, current_state} ->
      case parse_line(diagram_type, line, current_state) do
        {:ok, next_state} -> {:cont, {:ok, next_state}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, %{boundary_stack: []} = parsed_state} -> {:ok, parsed_state}
      {:ok, _parsed_state} -> {:error, "Mermaid import contains an unclosed group"}
      error -> error
    end
  end

  defp parse_line(_diagram_type, line, state)
       when line in ["}", "end"] and state.boundary_stack == [] do
    {:error, "Mermaid import contains an unmatched group terminator"}
  end

  defp parse_line(:state, line, state) do
    cond do
      String.starts_with?(line, "state ") and String.ends_with?(line, "{") ->
        open_state_boundary(line, state)

      line == "}" ->
        {:ok, %{state | boundary_stack: tl(state.boundary_stack)}}

      Regex.match?(@state_edge_pattern, line) ->
        import_state_edge(line, state)

      Regex.match?(@state_node_pattern, line) ->
        import_state_node(line, state)

      Regex.match?(@unsupported_directive_pattern, line) ->
        {:ok, add_unsupported_line(state, line)}

      String.starts_with?(line, "note ") ->
        {:ok, add_unsupported_line(state, line)}

      true ->
        {:error, "Unsupported Mermaid state diagram syntax"}
    end
  end

  defp parse_line(:flowchart, line, state) do
    cond do
      String.starts_with?(line, "subgraph ") ->
        open_flowchart_boundary(line, state)

      line == "end" ->
        {:ok, %{state | boundary_stack: tl(state.boundary_stack)}}

      Regex.match?(@edge_pattern, line) ->
        import_flowchart_edge(line, state)

      Regex.match?(@unsupported_directive_pattern, line) ->
        {:ok, add_unsupported_line(state, line)}

      true ->
        import_flowchart_node(line, state)
    end
  end

  defp open_state_boundary(line, state) do
    if state.boundary_stack != [] do
      {:error, "Nested Mermaid state groups are not supported"}
    else
      case parse_state_boundary(line) do
        {:ok, label, ref} ->
          {next_state, boundary_id} = ensure_boundary(state, ref || label, label)
          {:ok, %{next_state | boundary_stack: [boundary_id | next_state.boundary_stack]}}

        :error ->
          {:error, "Unsupported Mermaid state group syntax"}
      end
    end
  end

  defp open_flowchart_boundary(line, state) do
    if state.boundary_stack != [] do
      {:error, "Nested Mermaid flowchart subgraphs are not supported"}
    else
      case parse_subgraph_boundary(line) do
        {:ok, label, ref} ->
          {next_state, boundary_id} = ensure_boundary(state, ref || label, label)

          {:ok,
           next_state
           |> Map.update!(:implicit_boundary_count, &(&1 + 1))
           |> Map.put(:boundary_stack, [boundary_id | next_state.boundary_stack])}

        :error ->
          {:error, "Unsupported Mermaid flowchart subgraph syntax"}
      end
    end
  end

  defp import_state_node(line, state) do
    captures = Regex.named_captures(@state_node_pattern, line)
    parent_id = List.first(state.boundary_stack)
    label = decode_label(captures["label"])
    {type, inferred?} = infer_node_type(label, parent_id, nil, :state)

    next_state =
      upsert_node(state, captures["ref"], %{
        label: label,
        type: type,
        parent: parent_id,
        inferred?: inferred?
      })

    {:ok, next_state}
  end

  defp import_state_edge(line, state) do
    captures = Regex.named_captures(@state_edge_pattern, line)

    if captures["source"] == "[*]" or captures["target"] == "[*]" do
      {:ok, add_unsupported_line(state, line)}
    else
      {state_with_source, source_id} = ensure_reference_node(state, captures["source"], :state)

      {state_with_target, target_id} =
        ensure_reference_node(state_with_source, captures["target"], :state)

      label = decode_label(captures["label"] || "")
      {:ok, add_edge(state_with_target, source_id, target_id, label)}
    end
  end

  defp import_flowchart_edge(line, state) do
    captures = Regex.named_captures(@edge_pattern, line)

    with {:ok, left_node} <- parse_flowchart_node_token(captures["left"]),
         {:ok, right_node} <- parse_flowchart_node_token(captures["right"]) do
      {state_with_left, left_id} = ensure_flowchart_node(state, left_node)
      {state_with_right, right_id} = ensure_flowchart_node(state_with_left, right_node)
      label = decode_label(captures["label"] || "")
      {:ok, add_edge(state_with_right, left_id, right_id, label)}
    else
      :error -> {:error, "Unsupported Mermaid flowchart syntax"}
    end
  end

  defp import_flowchart_node(line, state) do
    case parse_flowchart_node_token(line) do
      {:ok, node_token} ->
        {next_state, _node_id} = ensure_flowchart_node(state, node_token)
        {:ok, next_state}

      :error ->
        {:error, "Unsupported Mermaid flowchart syntax"}
    end
  end

  defp ensure_reference_node(state, ref, mode) do
    case Map.get(state.ref_map, ref) do
      nil ->
        label = default_label_from_ref(ref)
        parent_id = List.first(state.boundary_stack)
        {type, inferred?} = infer_node_type(label, parent_id, nil, mode)

        next_state =
          upsert_node(state, ref, %{
            label: label,
            type: type,
            parent: parent_id,
            inferred?: inferred?
          })

        {next_state, Map.fetch!(next_state.ref_map, ref)}

      node_id ->
        {state, node_id}
    end
  end

  defp ensure_flowchart_node(state, %{ref: ref, label: label, shape: shape}) do
    case Map.get(state.ref_map, ref) do
      nil ->
        parent_id = List.first(state.boundary_stack)
        {type, inferred?} = infer_node_type(label, parent_id, shape, :flowchart)

        next_state =
          upsert_node(state, ref, %{
            label: label,
            type: type,
            parent: parent_id,
            inferred?: inferred?
          })

        {next_state, Map.fetch!(next_state.ref_map, ref)}

      node_id ->
        {state, node_id}
    end
  end

  defp upsert_node(state, ref, attrs) do
    case Map.get(state.ref_map, ref) do
      nil ->
        node_id = navigator_node_id(ref, state.next_node_index)

        node = %{
          "data" => %{
            "id" => node_id,
            "data_tags" => [],
            "description" => nil,
            "label" => attrs.label,
            "linked_threats" => [],
            "out_of_scope" => "false",
            "parent" => attrs.parent,
            "security_tags" => [],
            "technology_tags" => [],
            "type" => attrs.type
          },
          "grabbable" => "true",
          "position" => default_position(state.next_node_index)
        }

        state
        |> Map.update!(:nodes, &Map.put(&1, node_id, node))
        |> Map.update!(:ref_map, &Map.put(&1, ref, node_id))
        |> Map.update!(:next_node_index, &(&1 + 1))
        |> maybe_increment_inferred_count(attrs.inferred?)

      node_id ->
        state
        |> Map.update!(:nodes, fn nodes ->
          Map.update!(nodes, node_id, fn node ->
            put_in(
              node,
              ["data"],
              Map.merge(node["data"], %{
                "label" => attrs.label,
                "parent" => attrs.parent,
                "type" => attrs.type
              })
            )
          end)
        end)
    end
  end

  defp ensure_boundary(state, ref, label) do
    boundary_ref = "boundary:" <> sanitize_token(ref)

    next_state =
      upsert_node(state, boundary_ref, %{
        label: decode_label(label),
        type: "trust_boundary",
        parent: nil,
        inferred?: false
      })

    {next_state, Map.fetch!(next_state.ref_map, boundary_ref)}
  end

  defp add_edge(state, source_id, target_id, label) do
    edge_id = "edge-import-#{state.next_edge_index}"

    edge = %{
      "data" => %{
        "id" => edge_id,
        "data_tags" => [],
        "description" => nil,
        "label" => label,
        "linked_threats" => [],
        "out_of_scope" => "false",
        "security_tags" => [],
        "source" => source_id,
        "target" => target_id,
        "technology_tags" => [],
        "type" => "edge"
      }
    }

    state
    |> Map.update!(:edges, &Map.put(&1, edge_id, edge))
    |> Map.update!(:next_edge_index, &(&1 + 1))
  end

  defp build_preview(state) do
    trust_boundary_count =
      state.nodes
      |> Map.values()
      |> Enum.count(&(&1["data"]["type"] == "trust_boundary"))

    warnings =
      []
      |> maybe_add_metadata_defaults_warning(
        map_size(state.nodes) > 0 or map_size(state.edges) > 0
      )
      |> maybe_add_inferred_warning(state.inferred_node_count)
      |> maybe_add_implicit_boundary_warning(state.implicit_boundary_count)
      |> maybe_add_unsupported_warning(state.unsupported_lines)

    %{
      nodes: state.nodes,
      edges: state.edges,
      warnings: warnings,
      summary: %{
        nodes: map_size(state.nodes),
        edges: map_size(state.edges),
        trust_boundaries: trust_boundary_count
      }
    }
  end

  defp maybe_add_metadata_defaults_warning(warnings, true) do
    warnings ++
      [
        %{
          code: :metadata_defaults,
          message:
            "Navigator will apply default metadata for imported elements because Mermaid does not carry tags, linked threats, descriptions, or coordinates."
        }
      ]
  end

  defp maybe_add_metadata_defaults_warning(warnings, false), do: warnings

  defp maybe_add_inferred_warning(warnings, count) when count > 0 do
    warnings ++
      [
        %{
          code: :inferred_node_type,
          message: "Navigator inferred node types for #{count} imported node(s)."
        }
      ]
  end

  defp maybe_add_inferred_warning(warnings, _count), do: warnings

  defp maybe_add_implicit_boundary_warning(warnings, count) when count > 0 do
    warnings ++
      [
        %{
          code: :implicit_boundary,
          message: "Navigator converted #{count} Mermaid subgraph(s) into trust boundaries."
        }
      ]
  end

  defp maybe_add_implicit_boundary_warning(warnings, _count), do: warnings

  defp maybe_add_unsupported_warning(warnings, []), do: warnings

  defp maybe_add_unsupported_warning(warnings, lines) do
    examples =
      lines
      |> Enum.uniq()
      |> Enum.take(3)
      |> Enum.join("; ")

    warnings ++
      [
        %{
          code: :unsupported_construct,
          message:
            "Navigator ignored #{length(lines)} unsupported Mermaid construct(s): #{examples}"
        }
      ]
  end

  defp add_unsupported_line(state, line) do
    Map.update!(state, :unsupported_lines, &(&1 ++ [line]))
  end

  defp parse_state_boundary(line) do
    cond do
      captures =
          Regex.named_captures(
            ~r/^state\s+"(?<label>[^"]+)"\s+as\s+(?<ref>[A-Za-z0-9_.-]+)\s*\{$/,
            line
          ) ->
        {:ok, captures["label"], captures["ref"]}

      captures =
          Regex.named_captures(
            ~r/^state\s+(?<label>[^\{]+?)\s+as\s+(?<ref>[A-Za-z0-9_.-]+)\s*\{$/,
            line
          ) ->
        {:ok, String.trim(captures["label"]), captures["ref"]}

      captures = Regex.named_captures(~r/^state\s+"(?<label>[^"]+)"\s*\{$/, line) ->
        {:ok, captures["label"], nil}

      captures = Regex.named_captures(~r/^state\s+(?<label>[^\{]+?)\s*\{$/, line) ->
        {:ok, String.trim(captures["label"]), nil}

      true ->
        :error
    end
  end

  defp parse_subgraph_boundary(line) do
    cond do
      captures =
          Regex.named_captures(~r/^subgraph\s+(?<ref>[A-Za-z0-9_.-]+)\[(?<label>.+)\]$/, line) ->
        {:ok, captures["label"], captures["ref"]}

      captures = Regex.named_captures(~r/^subgraph\s+"(?<label>[^"]+)"$/, line) ->
        {:ok, captures["label"], nil}

      captures = Regex.named_captures(~r/^subgraph\s+(?<label>.+)$/, line) ->
        {:ok, String.trim(captures["label"]), nil}

      true ->
        :error
    end
  end

  defp parse_flowchart_node_token(token) do
    token = String.trim(token)

    cond do
      captures = Regex.named_captures(~r/^(?<ref>[A-Za-z0-9_.-]+)\[\((?<label>.+)\)\]$/, token) ->
        {:ok, %{ref: captures["ref"], label: decode_label(captures["label"]), shape: :datastore}}

      captures = Regex.named_captures(~r/^(?<ref>[A-Za-z0-9_.-]+)\{\{(?<label>.+)\}\}$/, token) ->
        {:ok, %{ref: captures["ref"], label: decode_label(captures["label"]), shape: :actor}}

      captures = Regex.named_captures(~r/^(?<ref>[A-Za-z0-9_.-]+)\((?<label>.+)\)$/, token) ->
        {:ok, %{ref: captures["ref"], label: decode_label(captures["label"]), shape: :process}}

      captures = Regex.named_captures(~r/^(?<ref>[A-Za-z0-9_.-]+)\[(?<label>.+)\]$/, token) ->
        {:ok, %{ref: captures["ref"], label: decode_label(captures["label"]), shape: :process}}

      captures = Regex.named_captures(~r/^(?<ref>[A-Za-z0-9_.-]+)$/, token) ->
        {:ok,
         %{ref: captures["ref"], label: default_label_from_ref(captures["ref"]), shape: :plain}}

      true ->
        :error
    end
  end

  defp infer_node_type(label, parent_id, shape, mode) do
    cond do
      shape == :datastore -> {"datastore", false}
      shape == :process -> {"process", false}
      shape == :actor -> {"actor", false}
      storage_label?(label) -> {"datastore", true}
      process_label?(label) -> {"process", true}
      actor_label?(label) -> {"actor", true}
      mode == :state and parent_id -> {"process", true}
      true -> {"actor", true}
    end
  end

  defp storage_label?(label) do
    Regex.match?(
      ~r/\b(db|database|repo|repository|repositories|storage|bucket|queue|cache|store|table)\b/i,
      label
    )
  end

  defp process_label?(label) do
    Regex.match?(
      ~r/\b(auth|authentication|process|service|api|gateway|worker|lambda|function|engine|processor)\b/i,
      label
    )
  end

  defp actor_label?(label) do
    Regex.match?(
      ~r/\b(user|admin|actor|client|customer|browser|operator|application|actions?)\b/i,
      label
    )
  end

  defp maybe_increment_inferred_count(state, true) do
    Map.update!(state, :inferred_node_count, &(&1 + 1))
  end

  defp maybe_increment_inferred_count(state, false), do: state

  defp navigator_node_id(ref, next_index) do
    sanitized = sanitize_token(ref)

    cond do
      String.starts_with?(sanitized, "node") -> sanitized
      true -> "node-import-#{next_index}"
    end
  end

  defp sanitize_token(token) do
    token
    |> to_string()
    |> String.trim()
    |> String.replace(~r/[^A-Za-z0-9_.-]/, "_")
    |> case do
      "" -> "node"
      sanitized -> sanitized
    end
  end

  defp default_label_from_ref(ref) do
    ref
    |> sanitize_token()
    |> String.replace(~r/^[a-z]+[_-]?/i, "")
    |> case do
      "" -> ref
      trimmed -> trimmed
    end
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> Naming.humanize()
  end

  defp decode_label(nil), do: ""

  defp decode_label(label) do
    label
    |> String.trim()
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#91;", "[")
    |> String.replace("&#93;", "]")
    |> String.replace("&#40;", "(")
    |> String.replace("&#41;", ")")
  end

  defp default_position(index) do
    column = rem(index - 1, 4)
    row = div(index - 1, 4)

    %{
      "x" => 180 * column,
      "y" => 140 * row
    }
  end
end
