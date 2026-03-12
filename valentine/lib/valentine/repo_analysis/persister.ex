defmodule Valentine.RepoAnalysis.Persister do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Valentine.AIResponseNormalizer
  alias Valentine.Composer
  alias Valentine.Composer.Assumption
  alias Valentine.Composer.AssumptionThreat
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.MitigationThreat
  alias Valentine.Composer.Threat
  alias Valentine.Repo

  @generated_tags ["AI generated", "GitHub import"]
  @boundary_columns 2
  @boundary_center_x 520
  @boundary_center_y 360
  @boundary_gap_x 980
  @boundary_gap_y 760
  @boundary_inner_start_x 170
  @boundary_inner_start_y 150
  @node_gap_x 260
  @lane_gap_y 180
  @lane_row_gap 110
  @boundary_layout_padding_x 320
  @boundary_layout_padding_y 260
  @root_origin_x 220
  @root_origin_y 980

  def persist(workspace_id, analysis) do
    case Repo.transaction(fn ->
           upsert_application_information(workspace_id, analysis.application_information)
           upsert_architecture(workspace_id, analysis.architecture)

           {persisted_threats, threat_ids_by_component} =
             upsert_threats(workspace_id, analysis.threats)

           persisted_assumptions =
             upsert_assumptions(workspace_id, analysis.assumptions, persisted_threats)

           persisted_mitigations =
             upsert_mitigations(workspace_id, analysis.mitigations, persisted_threats)

           generated_threat_ids = MapSet.new(Enum.map(persisted_threats, & &1.id))

           sync_assumption_links(persisted_assumptions, generated_threat_ids)
           sync_mitigation_links(persisted_mitigations, generated_threat_ids)
           upsert_data_flow_diagram(workspace_id, analysis.dfd, threat_ids_by_component)
           :ok
         end) do
      {:ok, :ok} -> :ok
      {:error, reason} -> raise "Repo analysis persistence failed: #{inspect(reason)}"
    end
  end

  defp upsert_application_information(workspace_id, content) do
    case Composer.get_workspace!(workspace_id, [:application_information]).application_information do
      nil ->
        Composer.create_application_information(%{workspace_id: workspace_id, content: content})

      application_information ->
        Composer.update_application_information(application_information, %{content: content})
    end
  end

  defp upsert_architecture(workspace_id, content) do
    case Composer.get_workspace!(workspace_id, [:architecture]).architecture do
      nil ->
        Composer.create_architecture(%{workspace_id: workspace_id, content: content, image: ""})

      architecture ->
        Composer.update_architecture(architecture, %{content: content})
    end
  end

  defp upsert_assumptions(workspace_id, assumptions, threats) do
    existing_assumptions = existing_assumptions_by_key(workspace_id)

    {persisted_assumptions, remaining_assumptions} =
      Enum.map_reduce(assumptions, existing_assumptions, fn assumption_json, acc ->
        assumption_attrs = assumption_attrs(workspace_id, assumption_json)
        assumption_key = assumption_key(assumption_attrs)

        case pop_existing(acc, assumption_key) do
          {nil, updated_acc} ->
            assumption = unwrap_result(Composer.create_assumption(assumption_attrs))
            {{assumption, assumption_json}, updated_acc}

          {existing_assumption, updated_acc} ->
            assumption =
              unwrap_result(
                Composer.update_assumption(
                  existing_assumption,
                  preserve_non_generated_tags(assumption_attrs, existing_assumption.tags)
                )
              )

            {{assumption, assumption_json}, updated_acc}
        end
      end)

    delete_stale_records(remaining_assumptions, &Composer.delete_assumption/1)

    synchronize_existing_links(persisted_assumptions, threats)
  end

  defp upsert_mitigations(workspace_id, mitigations, threats) do
    existing_mitigations = existing_mitigations_by_key(workspace_id)

    {persisted_mitigations, remaining_mitigations} =
      Enum.map_reduce(mitigations, existing_mitigations, fn mitigation_json, acc ->
        mitigation_attrs = mitigation_attrs(workspace_id, mitigation_json)
        mitigation_key = mitigation_key(mitigation_attrs)

        case pop_existing(acc, mitigation_key) do
          {nil, updated_acc} ->
            mitigation = unwrap_result(Composer.create_mitigation(mitigation_attrs))
            {{mitigation, mitigation_json}, updated_acc}

          {existing_mitigation, updated_acc} ->
            mitigation =
              unwrap_result(
                Composer.update_mitigation(
                  existing_mitigation,
                  preserve_non_generated_tags(mitigation_attrs, existing_mitigation.tags)
                )
              )

            {{mitigation, mitigation_json}, updated_acc}
        end
      end)

    delete_stale_records(remaining_mitigations, &Composer.delete_mitigation/1)

    synchronize_existing_links(persisted_mitigations, threats)
  end

  defp upsert_threats(workspace_id, threats) do
    existing_threats = existing_threats_by_key(workspace_id)

    {persisted_threats, remaining_threats} =
      Enum.map_reduce(threats, existing_threats, fn threat_json, acc ->
        threat_attrs = threat_attrs(workspace_id, threat_json)
        threat_key = threat_key(threat_attrs)

        case pop_existing(acc, threat_key) do
          {nil, updated_acc} ->
            persisted_threat = unwrap_result(Composer.create_threat(threat_attrs))
            {{persisted_threat, threat_json}, updated_acc}

          {existing_threat, updated_acc} ->
            persisted_threat =
              unwrap_result(
                Composer.update_threat(
                  existing_threat,
                  preserve_non_generated_tags(threat_attrs, existing_threat.tags)
                )
              )

            {{persisted_threat, threat_json}, updated_acc}
        end
      end)

    delete_stale_records(remaining_threats, &Composer.delete_threat/1)

    threat_ids_by_component =
      Enum.reduce(persisted_threats, %{}, fn {persisted_threat, threat_json}, acc ->
        Enum.reduce(threat_json["related_component_ids"] || [], acc, fn component_id, map ->
          Map.update(map, component_id, [persisted_threat.id], &[persisted_threat.id | &1])
        end)
      end)

    {Enum.map(persisted_threats, &elem(&1, 0)), threat_ids_by_component}
  end

  defp upsert_data_flow_diagram(workspace_id, dfd, threat_ids_by_component) do
    boundaries = dfd["boundaries"] || []
    components = dfd["components"] || []
    flows = dfd["flows"] || []
    layout = build_layout(boundaries, components, flows)

    boundary_nodes =
      Enum.map(boundaries, fn boundary ->
        {boundary["id"],
         node(
           boundary["id"],
           boundary["label"],
           "trust_boundary",
           boundary["description"],
           nil,
           [],
           Map.get(layout.boundaries, boundary["id"], %{"x" => 50, "y" => 50})
         )}
      end)
      |> Map.new()

    component_nodes =
      Enum.map(components, fn component ->
        linked_threats = Map.get(threat_ids_by_component, component["id"], [])
        component_type = normalize_component_type(component["kind"])

        {component["id"],
         node(
           component["id"],
           component["label"],
           component_type,
           component["description"],
           component["boundary_id"],
           linked_threats,
           Map.get(layout.components, component["id"], %{"x" => 50, "y" => 50})
         )}
      end)
      |> Map.new()

    nodes = Map.merge(boundary_nodes, component_nodes)

    edges =
      flows
      |> Enum.with_index(1)
      |> Enum.map(fn {flow, index} ->
        edge_id = "edge-#{index}"
        linked_threats = Map.get(threat_ids_by_component, flow["source"], [])

        {edge_id,
         %{
           "data" => %{
             "id" => edge_id,
             "data_tags" => [],
             "description" => flow["description"],
             "label" => flow["label"],
             "linked_threats" => linked_threats,
             "out_of_scope" => "false",
             "security_tags" => [],
             "source" => flow["source"],
             "target" => flow["target"],
             "technology_tags" => [],
             "type" => "edge"
           }
         }}
      end)
      |> Map.new()

    case Composer.get_data_flow_diagram_by_workspace_id(workspace_id) do
      nil ->
        Composer.create_data_flow_diagram(%{
          workspace_id: workspace_id,
          nodes: nodes,
          edges: edges
        })

      data_flow_diagram ->
        Composer.update_data_flow_diagram(data_flow_diagram, %{nodes: nodes, edges: edges})
    end
  end

  defp node(id, label, type, description, parent, linked_threats, position) do
    %{
      "data" => %{
        "id" => id,
        "data_tags" => [],
        "description" => description,
        "label" => label,
        "linked_threats" => linked_threats,
        "out_of_scope" => "false",
        "parent" => parent,
        "security_tags" => [],
        "technology_tags" => [],
        "type" => type
      },
      "grabbable" => "true",
      "position" => position
    }
  end

  defp build_layout(boundaries, components, flows) do
    boundary_ids = MapSet.new(Enum.map(boundaries, & &1["id"]))
    component_levels = component_levels(components, flows)
    boundary_components = components_by_boundary(components, boundary_ids)
    boundary_dimensions = boundary_dimensions(boundaries, boundary_components, component_levels)

    max_boundary_width = max_boundary_dimension(boundary_dimensions, :width, @boundary_gap_x)
    max_boundary_height = max_boundary_dimension(boundary_dimensions, :height, @boundary_gap_y)

    boundary_gap_x = max(@boundary_gap_x, max_boundary_width)
    boundary_gap_y = max(@boundary_gap_y, max_boundary_height)

    boundary_positions =
      boundaries
      |> Enum.sort_by(&(&1["label"] || &1["id"] || ""))
      |> Enum.with_index()
      |> Map.new(fn {boundary, index} ->
        {column, row} = {rem(index, @boundary_columns), div(index, @boundary_columns)}

        {boundary["id"],
         %{
           "x" => @boundary_center_x + column * boundary_gap_x,
           "y" => @boundary_center_y + row * boundary_gap_y
         }}
      end)

    component_positions =
      components
      |> Enum.group_by(fn component ->
        boundary_id = component["boundary_id"]

        if is_binary(boundary_id) and MapSet.member?(boundary_ids, boundary_id) do
          {:boundary, boundary_id}
        else
          :root
        end
      end)
      |> Enum.reduce(%{}, fn {group, group_components}, acc ->
        Map.merge(
          acc,
          group_component_positions(
            group,
            group_components,
            component_levels,
            boundary_positions,
            boundary_dimensions
          )
        )
      end)

    %{boundaries: boundary_positions, components: component_positions}
  end

  defp group_component_positions(
         {:boundary, _boundary_id},
         components,
         component_levels,
         _boundary_positions,
         _boundary_dimensions
       ) do
    layout_positions(
      components,
      component_levels,
      @boundary_inner_start_x,
      @boundary_inner_start_y
    )
  end

  defp group_component_positions(
         :root,
         components,
         component_levels,
         boundary_positions,
         boundary_dimensions
       ) do
    boundary_bottom =
      boundary_positions
      |> Enum.map(fn {boundary_id, position} ->
        dimension = Map.get(boundary_dimensions, boundary_id, %{height: @boundary_gap_y})
        position["y"] + div(dimension.height, 2)
      end)
      |> Enum.max(fn -> @root_origin_y - @boundary_layout_padding_y end)

    base_y = max(@root_origin_y, boundary_bottom + div(@boundary_layout_padding_y, 2))

    layout_positions(components, component_levels, @root_origin_x, base_y)
  end

  defp layout_positions(components, component_levels, start_x, start_y) do
    components
    |> Enum.sort_by(fn component ->
      {
        Map.get(component_levels, component["id"], 0),
        component_type_priority(normalize_component_type(component["kind"])),
        component["label"] || component["id"] || ""
      }
    end)
    |> Enum.group_by(&Map.get(component_levels, &1["id"], 0))
    |> Enum.sort_by(fn {level, _components} -> level end)
    |> Enum.flat_map(fn {level, level_components} ->
      level_components
      |> Enum.group_by(&component_lane(normalize_component_type(&1["kind"])))
      |> Enum.sort_by(fn {lane, _components} -> lane end)
      |> Enum.flat_map(fn {lane, lane_components} ->
        lane_components
        |> Enum.sort_by(&(&1["label"] || &1["id"] || ""))
        |> Enum.with_index()
        |> Enum.map(fn {component, row} ->
          {component["id"],
           %{
             "x" => start_x + level * @node_gap_x,
             "y" => start_y + lane * @lane_gap_y + row * @lane_row_gap
           }}
        end)
      end)
    end)
    |> Map.new()
  end

  defp components_by_boundary(components, boundary_ids) do
    Enum.group_by(components, fn component ->
      boundary_id = component["boundary_id"]

      if is_binary(boundary_id) and MapSet.member?(boundary_ids, boundary_id) do
        boundary_id
      else
        nil
      end
    end)
  end

  defp boundary_dimensions(boundaries, boundary_components, component_levels) do
    Map.new(boundaries, fn boundary ->
      components = Map.get(boundary_components, boundary["id"], [])
      {boundary["id"], estimate_group_dimensions(components, component_levels)}
    end)
  end

  defp max_boundary_dimension(boundary_dimensions, key, fallback) do
    boundary_dimensions
    |> Map.values()
    |> Enum.map(&Map.get(&1, key, fallback))
    |> Enum.max(fn -> fallback end)
  end

  defp estimate_group_dimensions([], _component_levels) do
    %{width: @boundary_gap_x, height: @boundary_gap_y}
  end

  defp estimate_group_dimensions(components, component_levels) do
    positions = layout_positions(components, component_levels, 0, 0)

    max_x =
      positions
      |> Map.values()
      |> Enum.map(& &1["x"])
      |> Enum.max(fn -> 0 end)

    max_y =
      positions
      |> Map.values()
      |> Enum.map(& &1["y"])
      |> Enum.max(fn -> 0 end)

    %{
      width: max(max_x + @boundary_layout_padding_x, @boundary_gap_x),
      height: max(max_y + @boundary_layout_padding_y, @boundary_gap_y)
    }
  end

  defp component_lane("actor"), do: 0
  defp component_lane("process"), do: 1
  defp component_lane("datastore"), do: 2
  defp component_lane(_type), do: 1

  defp component_levels(components, flows) do
    component_ids = MapSet.new(Enum.map(components, & &1["id"]))

    graph =
      Enum.reduce(flows, %{outgoing: %{}, indegree: initial_indegree(component_ids)}, fn flow,
                                                                                         acc ->
        source = flow["source"]
        target = flow["target"]

        if MapSet.member?(component_ids, source) and MapSet.member?(component_ids, target) do
          %{
            outgoing: Map.update(acc.outgoing, source, [target], &[target | &1]),
            indegree: Map.update!(acc.indegree, target, &(&1 + 1))
          }
        else
          acc
        end
      end)

    roots =
      graph.indegree
      |> Enum.filter(fn {_id, indegree} -> indegree == 0 end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    roots =
      if roots == [],
        do: component_ids |> MapSet.to_list() |> Enum.sort() |> Enum.take(1),
        else: roots

    {levels, _indegree} = assign_levels(roots, graph.outgoing, graph.indegree, %{})

    remaining_ids =
      component_ids
      |> MapSet.to_list()
      |> Enum.reject(&Map.has_key?(levels, &1))
      |> Enum.sort()

    fallback_level =
      levels
      |> Map.values()
      |> Enum.max(fn -> -1 end)
      |> Kernel.+(1)

    Enum.with_index(remaining_ids, fallback_level)
    |> Enum.reduce(levels, fn {id, level}, acc -> Map.put(acc, id, level) end)
  end

  defp assign_levels([], _outgoing, indegree, levels), do: {levels, indegree}

  defp assign_levels([id | rest], outgoing, indegree, levels) do
    current_level = Map.get(levels, id, 0)
    neighbors = Map.get(outgoing, id, []) |> Enum.uniq() |> Enum.sort()

    {next_queue, next_indegree, next_levels} =
      Enum.reduce(neighbors, {rest, indegree, Map.put_new(levels, id, current_level)}, fn target,
                                                                                          {queue,
                                                                                           indegree_acc,
                                                                                           levels_acc} ->
        updated_levels =
          Map.update(levels_acc, target, current_level + 1, &max(&1, current_level + 1))

        updated_indegree = Map.update!(indegree_acc, target, &max(&1 - 1, 0))

        updated_queue =
          if updated_indegree[target] == 0 and target not in queue do
            queue ++ [target]
          else
            queue
          end

        {updated_queue, updated_indegree, updated_levels}
      end)

    assign_levels(next_queue, outgoing, next_indegree, next_levels)
  end

  defp initial_indegree(component_ids) do
    component_ids
    |> MapSet.to_list()
    |> Map.new(&{&1, 0})
  end

  defp component_type_priority("external_entity"), do: 0
  defp component_type_priority("actor"), do: 0
  defp component_type_priority("process"), do: 1
  defp component_type_priority("data_store"), do: 2
  defp component_type_priority("datastore"), do: 2
  defp component_type_priority(_type), do: 3

  defp normalize_component_type("external_entity"), do: "actor"
  defp normalize_component_type("data_store"), do: "datastore"
  defp normalize_component_type(type) when is_binary(type), do: type
  defp normalize_component_type(_type), do: "process"

  defp assumption_attrs(workspace_id, assumption_json) do
    %{
      workspace_id: workspace_id,
      content: normalize_text(assumption_json["content"]),
      tags: @generated_tags
    }
  end

  defp mitigation_attrs(workspace_id, mitigation_json) do
    %{
      workspace_id: workspace_id,
      content: normalize_text(mitigation_json["content"]),
      tags: @generated_tags
    }
  end

  defp threat_attrs(workspace_id, threat_json) do
    threat = AIResponseNormalizer.threat_from_json(threat_json)

    %{
      workspace_id: workspace_id,
      threat_source: normalize_text(threat.threat_source),
      prerequisites: normalize_text(threat.prerequisites),
      threat_action: normalize_text(threat.threat_action),
      threat_impact: normalize_text(threat.threat_impact),
      impacted_goal: normalize_string_list(threat.impacted_goal),
      impacted_assets: normalize_string_list(threat.impacted_assets),
      stride: normalize_atom_list(threat.stride),
      tags: @generated_tags
    }
  end

  defp synchronize_existing_links(persisted_records, threats) do
    Enum.map(persisted_records, fn {record, record_json} ->
      {record, related_threat_indexes(record_json, threats)}
    end)
  end

  defp sync_assumption_links(persisted_assumptions, generated_threat_ids) do
    Enum.each(persisted_assumptions, fn {assumption, desired_threat_ids} ->
      assumption = Composer.get_assumption!(assumption.id, [:threats])

      sync_links(
        assumption.id,
        desired_threat_ids,
        generated_threat_ids,
        Enum.map(assumption.threats, & &1.id),
        AssumptionThreat,
        :assumption_id
      )
    end)
  end

  defp sync_mitigation_links(persisted_mitigations, generated_threat_ids) do
    Enum.each(persisted_mitigations, fn {mitigation, desired_threat_ids} ->
      mitigation = Composer.get_mitigation!(mitigation.id, [:threats])

      sync_links(
        mitigation.id,
        desired_threat_ids,
        generated_threat_ids,
        Enum.map(mitigation.threats, & &1.id),
        MitigationThreat,
        :mitigation_id
      )
    end)
  end

  defp sync_links(
         owner_id,
         desired_threat_ids,
         generated_threat_ids,
         existing_threat_ids,
         join_schema,
         owner_field
       ) do
    desired_set = MapSet.new(desired_threat_ids)

    existing_generated_set =
      existing_threat_ids
      |> Enum.filter(&MapSet.member?(generated_threat_ids, &1))
      |> MapSet.new()

    threat_ids_to_add = MapSet.difference(desired_set, existing_generated_set) |> MapSet.to_list()

    threat_ids_to_remove =
      MapSet.difference(existing_generated_set, desired_set) |> MapSet.to_list()

    Enum.each(threat_ids_to_add, fn threat_id ->
      unwrap_result(
        Repo.insert(
          struct(join_schema, %{owner_field => owner_id, threat_id: threat_id}),
          on_conflict: :nothing,
          conflict_target: [owner_field, :threat_id]
        )
      )
    end)

    if threat_ids_to_remove != [] do
      Repo.delete_all(
        from(join in join_schema,
          where:
            field(join, ^owner_field) == ^owner_id and join.threat_id in ^threat_ids_to_remove
        )
      )
    end
  end

  defp related_threat_indexes(record_json, threats) do
    record_json
    |> Map.get("related_threat_indexes", [])
    |> Enum.map(&threat_id_at(threats, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp threat_id_at(threats, index) when is_integer(index) and index >= 0 do
    case Enum.at(threats, index) do
      nil -> nil
      threat -> threat.id
    end
  end

  defp threat_id_at(_threats, _index), do: nil

  defp existing_assumptions_by_key(workspace_id) do
    workspace_id
    |> Composer.list_assumptions_by_workspace()
    |> existing_records_by_key(&assumption_key/1)
  end

  defp existing_mitigations_by_key(workspace_id) do
    workspace_id
    |> Composer.list_mitigations_by_workspace()
    |> existing_records_by_key(&mitigation_key/1)
  end

  defp existing_threats_by_key(workspace_id) do
    workspace_id
    |> Composer.list_threats_by_workspace()
    |> existing_records_by_key(&threat_key/1)
  end

  defp existing_records_by_key(records, key_fun) do
    records
    |> Enum.filter(&generated_record?/1)
    |> Enum.group_by(key_fun)
  end

  defp pop_existing(grouped_records, key) do
    case Map.get(grouped_records, key, []) do
      [record | remaining] ->
        updated_records =
          if remaining == [] do
            Map.delete(grouped_records, key)
          else
            Map.put(grouped_records, key, remaining)
          end

        {record, updated_records}

      [] ->
        {nil, grouped_records}
    end
  end

  defp delete_stale_records(grouped_records, delete_fun) do
    grouped_records
    |> Map.values()
    |> List.flatten()
    |> Enum.each(fn record ->
      unwrap_result(delete_fun.(record))
    end)
  end

  defp generated_record?(record) do
    tags = Map.get(record, :tags) || []
    Enum.all?(@generated_tags, &(&1 in tags))
  end

  defp preserve_non_generated_tags(attrs, existing_tags) do
    preserved_tags =
      existing_tags
      |> List.wrap()
      |> Enum.reject(&(&1 in @generated_tags))

    Map.put(attrs, :tags, Enum.uniq(@generated_tags ++ preserved_tags))
  end

  defp assumption_key(%Assumption{} = assumption),
    do: assumption_key(%{content: assumption.content})

  defp assumption_key(%{content: content}), do: normalize_text(content)

  defp mitigation_key(%Mitigation{} = mitigation),
    do: mitigation_key(%{content: mitigation.content})

  defp mitigation_key(%{content: content}), do: normalize_text(content)

  defp threat_key(%Threat{} = threat) do
    threat_key(%{
      threat_source: threat.threat_source,
      prerequisites: threat.prerequisites,
      threat_action: threat.threat_action,
      threat_impact: threat.threat_impact,
      impacted_goal: threat.impacted_goal,
      impacted_assets: threat.impacted_assets,
      stride: threat.stride
    })
  end

  defp threat_key(attrs) do
    {
      normalize_text(attrs[:threat_source]),
      normalize_text(attrs[:prerequisites]),
      normalize_text(attrs[:threat_action]),
      normalize_text(attrs[:threat_impact]),
      normalize_string_list(attrs[:impacted_goal]),
      normalize_string_list(attrs[:impacted_assets]),
      normalize_atom_list(attrs[:stride])
    }
  end

  defp normalize_text(value) when is_binary(value), do: String.trim(value)
  defp normalize_text(nil), do: nil
  defp normalize_text(value), do: value |> to_string() |> String.trim()

  defp normalize_string_list(values) do
    values
    |> List.wrap()
    |> Enum.map(&normalize_text/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_atom_list(values) do
    values
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn
      value when is_atom(value) -> value
      value when is_binary(value) -> String.to_existing_atom(value)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  rescue
    ArgumentError -> []
  end

  defp unwrap_result({:ok, value}), do: value
  defp unwrap_result({count, _}) when is_integer(count), do: count
  defp unwrap_result({:error, reason}), do: Repo.rollback(reason)
end
