defmodule ValentineWeb.WorkspaceLive.Import.JsonImport do
  alias Valentine.Composer
  alias Valentine.Repo

  def build_workspace(data, owner) do
    with {:ok, workspace} <- create_base_workspace(data, owner),
         :ok <- create_application_info(workspace.id, data),
         :ok <- create_architecture(workspace.id, data),
         crosswalks <- create_core_elements(workspace.id, data),
         :ok <- create_data_flow_diagram(workspace.id, data, crosswalks),
         :ok <- create_relationships(data, crosswalks) do
      {:ok, workspace}
    end
  end

  def process_json_file(path, owner) do
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
         true <- validate_required_fields(json["workspace"]) do
      {:ok, json["workspace"]}
    else
      {:missing_fields, fields} -> {:error, "Missing required fields: #{Enum.join(fields, ", ")}"}
      {:error, _} -> {:error, "Invalid JSON"}
    end
  end

  # Private functions

  defp create_base_workspace(data, owner) do
    name = get_in(data, ["name"]) || "Untitled Workspace"
    Composer.create_workspace(%{name: name, owner: owner})
  end

  defp create_application_info(workspace_id, data) do
    content = get_in(data, ["application_information", "content"]) || ""

    {:ok, _} =
      Composer.create_application_information(%{
        workspace_id: workspace_id,
        content: content
      })

    :ok
  end

  defp create_architecture(workspace_id, data) do
    content = get_in(data, ["architecture", "content"]) || ""
    image = get_in(data, ["architecture", "image"]) || ""

    {:ok, _} =
      Composer.create_architecture(%{
        workspace_id: workspace_id,
        content: content,
        image: image
      })

    :ok
  end

  defp create_data_flow_diagram(workspace_id, data, crosswalks) do
    edges = get_in(data, ["data_flow_diagram", "edges"]) || %{}
    nodes = get_in(data, ["data_flow_diagram", "nodes"]) || %{}

    # For each node, replace any linked_threats with the corresponding threat ID from the crosswalk
    nodes =
      Enum.reduce(nodes, %{}, fn {id, node}, acc ->
        threats =
          Enum.map(node["data"]["linked_threats"], fn threat_id ->
            Map.fetch!(crosswalks[:threats], threat_id)
          end)

        node = put_in(node["data"]["linked_threats"], threats)
        Map.put(acc, id, node)
      end)

    # For each edge, replace any linked_threats with the corresponding threat ID from the crosswalk
    edges =
      Enum.reduce(edges, %{}, fn {id, edge}, acc ->
        threats =
          Enum.map(edge["data"]["linked_threats"], fn threat_id ->
            Map.fetch!(crosswalks[:threats], threat_id)
          end)

        edge = put_in(edge["data"]["linked_threats"], threats)
        Map.put(acc, id, edge)
      end)

    {:ok, _} =
      Composer.create_data_flow_diagram(%{
        workspace_id: workspace_id,
        edges: edges,
        nodes: nodes
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
        content: assumption["content"],
        comments: assumption["comments"],
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
        comments: mitigation["comments"],
        status: mitigation["status"],
        tags: mitigation["tags"]
      })
    end)
  end

  defp create_threats(workspace_id, threats) do
    create_elements(threats, fn threat ->
      Composer.create_threat(%{
        workspace_id: workspace_id,
        numeric_id: threat["numericId"],
        threat_source: threat["threat_source"],
        prerequisites: threat["prerequisites"],
        threat_action: threat["threat_action"],
        threat_impact: threat["threat_impact"],
        impacted_goal: threat["impacted_goal"],
        impacted_assets: threat["impacted_assets"],
        status: threat["status"],
        priority: threat["priority"],
        stride: threat["stride"],
        comments: threat["comments"],
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
    create_assumption_links(data["assumptions"], crosswalks)
    create_mitigation_links(data["mitigations"], crosswalks)
    :ok
  end

  defp create_assumption_links(assumptions, crosswalks) do
    assumptions
    |> Enum.each(fn assumption ->
      assumption["threats"]
      |> Enum.each(fn threat_id ->
        create_assumption_threat_link(assumption["id"], threat_id, crosswalks)
      end)
    end)

    assumptions
    |> Enum.each(fn assumption ->
      assumption["mitigations"]
      |> Enum.each(fn mitigation_id ->
        create_assumption_mitigation_link(assumption["id"], mitigation_id, crosswalks)
      end)
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

  defp create_mitigation_links(mitigations, crosswalks) do
    mitigations
    |> Enum.each(fn mitigation ->
      mitigation["threats"]
      |> Enum.each(fn threat_id ->
        with {:ok, mitigation_id} <- Map.fetch(crosswalks.mitigations, mitigation["id"]),
             {:ok, threat_id} <- Map.fetch(crosswalks.threats, threat_id) do
          %Composer.MitigationThreat{
            mitigation_id: mitigation_id,
            threat_id: threat_id
          }
          |> Repo.insert()
        end
      end)
    end)
  end

  defp validate_required_fields(data) do
    required_keys =
      ~w(application_information architecture data_flow_diagram assumptions mitigations threats)

    missing_keys = Enum.filter(required_keys, &(!Map.has_key?(data, &1)))

    case missing_keys do
      [] -> true
      keys -> {:missing_fields, keys}
    end
  end
end
