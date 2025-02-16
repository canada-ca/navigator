defmodule ValentineWeb.WorkspaceLive.Import.TcImport do
  alias Valentine.Composer
  alias Valentine.Repo

  def build_workspace(data, owner) do
    with {:ok, workspace} <- create_base_workspace(data, owner),
         :ok <- create_application_info(workspace.id, data),
         :ok <- create_architecture(workspace.id, data),
         crosswalks <- create_core_elements(workspace.id, data),
         :ok <- create_relationships(data, crosswalks) do
      {:ok, workspace}
    end
  end

  def process_tc_file(path, owner) do
    with {:ok, json} <- File.read(path),
         {:ok, data} <- validate(json),
         {:ok, result} <- build_workspace(data, owner) do
      {:ok, {:ok, result}}
    else
      {:error, msg} when is_binary(msg) -> {:ok, {:error, msg}}
      {:error, _} -> {:ok, {:error, "Invalid file"}}
    end
  end

  def validate(data) do
    with {:ok, json} <- Jason.decode(data),
         true <- validate_required_fields(json) do
      {:ok, json}
    else
      {:missing_fields, fields} -> {:error, "Missing required fields: #{Enum.join(fields, ", ")}"}
      {:error, _} -> {:error, "Invalid JSON"}
    end
  end

  # Private functions

  defp create_base_workspace(data, owner) do
    name = get_in(data, ["applicationInfo", "name"]) || "Untitled Workspace"
    Composer.create_workspace(%{name: name, owner: owner})
  end

  defp create_application_info(workspace_id, data) do
    description = get_in(data, ["applicationInfo", "description"]) || ""

    {:ok, _} =
      Composer.create_application_information(%{
        workspace_id: workspace_id,
        content: MDEx.to_html!(description, extension: [shortcodes: true])
      })

    :ok
  end

  defp create_architecture(workspace_id, data) do
    description = get_in(data, ["architecture", "description"]) || ""
    image = get_in(data, ["architecture", "image"]) || ""

    content = MDEx.to_html!(description, extension: [shortcodes: true])

    # Prepend image to content if it exists
    content =
      if image != "" do
        "<p><img src=\"#{image}\" alt=\"Architecture Diagram\" /></p>" <> content
      else
        content
      end

    {:ok, _} =
      Composer.create_architecture(%{
        workspace_id: workspace_id,
        content: content
      })

    :ok
  end

  defp create_core_elements(workspace_id, data) do
    %{
      assumptions: create_assumptions(workspace_id, data["assumptions"]),
      mitigations: create_mitigations(workspace_id, data["mitigations"]),
      threats: create_threats(workspace_id, data["threats"])
    }
  end

  defp create_assumptions(workspace_id, assumptions) do
    create_elements(assumptions, fn assumption ->
      Composer.create_assumption(%{
        workspace_id: workspace_id,
        numeric_id: assumption["numericId"],
        content: assumption["content"],
        comments: get_metadata_value(assumption["metadata"], "Comments"),
        tags: assumption["tags"]
      })
    end)
  end

  defp create_mitigations(workspace_id, mitigations) do
    create_elements(mitigations, fn mitigation ->
      Composer.create_mitigation(%{
        workspace_id: workspace_id,
        numeric_id: mitigation["numericId"],
        content: mitigation["content"],
        comments: get_metadata_value(mitigation["metadata"], "Comments"),
        tags: mitigation["tags"]
      })
    end)
  end

  defp create_threats(workspace_id, threats) do
    create_elements(threats, fn threat ->
      Composer.create_threat(%{
        workspace_id: workspace_id,
        numeric_id: threat["numericId"],
        threat_source: threat["threatSource"],
        prerequisites: threat["prerequisites"],
        threat_action: threat["threatAction"],
        threat_impact: threat["threatImpact"],
        impacted_goal: threat["impactedGoal"],
        impacted_assets: threat["impactedAssets"],
        status: get_threat_status(threat["status"]),
        priority: get_metadata_value(threat["metadata"], "Priority"),
        stride: get_stride_values(threat["metadata"]),
        comments: get_metadata_value(threat["metadata"], "Comments"),
        tags: threat["tags"]
      })
    end)
  end

  defp create_elements(elements, creation_func) do
    elements
    |> Enum.reduce(%{}, fn element, acc ->
      {:ok, new_element} = creation_func.(element)
      Map.put(acc, element["id"], new_element.id)
    end)
  end

  defp create_relationships(data, crosswalks) do
    create_assumption_links(data["assumptionLinks"], crosswalks)
    create_mitigation_links(data["mitigationLinks"], crosswalks)
    :ok
  end

  defp create_assumption_links(links, crosswalks) do
    Enum.each(links, fn %{
                          "type" => type,
                          "linkedId" => linked_id,
                          "assumptionId" => assumption_id
                        } ->
      case type do
        "Threat" -> create_assumption_threat_link(assumption_id, linked_id, crosswalks)
        "Mitigation" -> create_assumption_mitigation_link(assumption_id, linked_id, crosswalks)
      end
    end)
  end

  defp create_assumption_threat_link(assumption_id, threat_id, crosswalks) do
    with {:ok, assumption_id} <- Map.fetch(crosswalks.assumptions, assumption_id),
         {:ok, threat_id} <- Map.fetch(crosswalks.threats, threat_id) do
      %Composer.AssumptionThreat{
        assumption_id: assumption_id,
        threat_id: threat_id
      }
      |> Repo.insert()
    end
  end

  defp create_assumption_mitigation_link(assumption_id, mitigation_id, crosswalks) do
    with {:ok, assumption_id} <- Map.fetch(crosswalks.assumptions, assumption_id),
         {:ok, mitigation_id} <- Map.fetch(crosswalks.mitigations, mitigation_id) do
      %Composer.AssumptionMitigation{
        assumption_id: assumption_id,
        mitigation_id: mitigation_id
      }
      |> Repo.insert()
    end
  end

  defp create_mitigation_links(links, crosswalks) do
    Enum.each(links, fn %{"linkedId" => threat_id, "mitigationId" => mitigation_id} ->
      with {:ok, mitigation_id} <- Map.fetch(crosswalks.mitigations, mitigation_id),
           {:ok, threat_id} <- Map.fetch(crosswalks.threats, threat_id) do
        %Composer.MitigationThreat{
          mitigation_id: mitigation_id,
          threat_id: threat_id
        }
        |> Repo.insert()
      end
    end)
  end

  defp validate_required_fields(data) do
    required_keys =
      ~w(schema applicationInfo architecture dataflow assumptions mitigations assumptionLinks mitigationLinks threats)

    missing_keys = Enum.filter(required_keys, &(!Map.has_key?(data, &1)))

    case missing_keys do
      [] -> true
      keys -> {:missing_fields, keys}
    end
  end

  defp get_metadata_value(nil, _key), do: ""

  defp get_metadata_value(data, key) do
    case Enum.find(data, &(&1["key"] == key)) do
      %{"value" => value} -> format_metadata_value(key, value)
      nil -> ""
    end
  end

  defp format_metadata_value("Priority", value), do: String.downcase(value)
  defp format_metadata_value(_, value), do: value

  defp get_stride_values(metadata) do
    case get_metadata_value(metadata, "STRIDE") do
      "" ->
        ""

      value ->
        %{
          "S" => :spoofing,
          "T" => :tampering,
          "I" => :information_disclosure,
          "R" => :repudiation,
          "D" => :denial_of_service,
          "E" => :elevation_of_privilege
        }
        |> Map.take(value)
        |> Map.values()
    end
  end

  defp get_threat_status(status) do
    %{
      "threatIdentified" => :identified,
      "threatResolved" => :resolved,
      "threatResolvedNotUseful" => :not_useful
    }[status]
  end
end
