defmodule Valentine.MCP.Tools.ThreatModeling do
  import Valentine.MCP.ToolHelpers

  alias Valentine.Composer

  def list_threats(_args, api_key) do
    api_key.workspace_id
    |> Composer.list_threats_by_workspace()
    |> ok_json()
  end

  def create_threat(args, api_key) do
    args
    |> attrs_for_create(api_key.workspace_id)
    |> Composer.create_threat()
    |> result_json()
  end

  def update_threat(%{"id" => id} = args, api_key) do
    with {:ok, threat} <- fetch_threat(id, api_key.workspace_id) do
      args
      |> attrs_for_update()
      |> then(&Composer.update_threat(threat, &1))
      |> result_json()
    else
      {:error, message} -> tool_error(message)
    end
  end

  def delete_threat(%{"id" => id}, api_key) do
    with {:ok, threat} <- fetch_threat(id, api_key.workspace_id) do
      threat
      |> Composer.delete_threat()
      |> result_json()
    else
      {:error, message} -> tool_error(message)
    end
  end

  def list_assumptions(_args, api_key) do
    api_key.workspace_id
    |> Composer.list_assumptions_by_workspace()
    |> ok_json()
  end

  def create_assumption(args, api_key) do
    args
    |> attrs_for_create(api_key.workspace_id)
    |> Composer.create_assumption()
    |> result_json()
  end

  def update_assumption(%{"id" => id} = args, api_key) do
    with {:ok, assumption} <- fetch_assumption(id, api_key.workspace_id) do
      args
      |> attrs_for_update()
      |> then(&Composer.update_assumption(assumption, &1))
      |> result_json()
    else
      {:error, message} -> tool_error(message)
    end
  end

  def delete_assumption(%{"id" => id}, api_key) do
    with {:ok, assumption} <- fetch_assumption(id, api_key.workspace_id) do
      assumption
      |> Composer.delete_assumption()
      |> result_json()
    else
      {:error, message} -> tool_error(message)
    end
  end

  def list_mitigations(_args, api_key) do
    api_key.workspace_id
    |> Composer.list_mitigations_by_workspace()
    |> ok_json()
  end

  def create_mitigation(args, api_key) do
    args
    |> attrs_for_create(api_key.workspace_id)
    |> Composer.create_mitigation()
    |> result_json()
  end

  def update_mitigation(%{"id" => id} = args, api_key) do
    with {:ok, mitigation} <- fetch_mitigation(id, api_key.workspace_id) do
      args
      |> attrs_for_update()
      |> then(&Composer.update_mitigation(mitigation, &1))
      |> result_json()
    else
      {:error, message} -> tool_error(message)
    end
  end

  def delete_mitigation(%{"id" => id}, api_key) do
    with {:ok, mitigation} <- fetch_mitigation(id, api_key.workspace_id) do
      mitigation
      |> Composer.delete_mitigation()
      |> result_json()
    else
      {:error, message} -> tool_error(message)
    end
  end

  def link_entities(args, api_key), do: change_link(args, api_key, :link)

  def unlink_entities(args, api_key), do: change_link(args, api_key, :unlink)

  defp change_link(
         %{
           "from_type" => from_type,
           "from_id" => from_id,
           "to_type" => to_type,
           "to_id" => to_id
         },
         api_key,
         action
       ) do
    with {:ok, from} <- fetch_entity(from_type, from_id, api_key.workspace_id),
         {:ok, to} <- fetch_entity(to_type, to_id, api_key.workspace_id),
         {:ok, result} <- call_relationship(action, from_type, from, to_type, to) do
      ok_json(result)
    else
      {:error, message} when is_binary(message) -> tool_error(message)
      {:error, entity} -> tool_error("Unable to update relationship for #{entity.id}")
    end
  end

  defp change_link(_args, _api_key, _action), do: tool_error("Invalid link arguments")

  defp attrs_for_create(args, workspace_id) do
    args
    |> normalize_attrs()
    |> Map.put("workspace_id", workspace_id)
  end

  defp attrs_for_update(args) do
    args
    |> normalize_attrs()
    |> Map.drop(["id", :id])
  end

  defp result_json({:ok, entity}), do: ok_json(entity)
  defp result_json({:error, changeset}), do: tool_error(Jason.encode!(format_error(changeset)))

  defp fetch_entity("threat", id, workspace_id), do: fetch_threat(id, workspace_id)
  defp fetch_entity("assumption", id, workspace_id), do: fetch_assumption(id, workspace_id)
  defp fetch_entity("mitigation", id, workspace_id), do: fetch_mitigation(id, workspace_id)
  defp fetch_entity(type, _id, _workspace_id), do: {:error, "Unsupported entity type: #{type}"}

  defp fetch_threat(id, workspace_id) do
    fetch_workspace_entity(
      &Composer.get_threat!(&1, [:assumptions, :mitigations]),
      id,
      workspace_id
    )
  end

  defp fetch_assumption(id, workspace_id) do
    fetch_workspace_entity(
      &Composer.get_assumption!(&1, [:threats, :mitigations]),
      id,
      workspace_id
    )
  end

  defp fetch_mitigation(id, workspace_id) do
    fetch_workspace_entity(
      &Composer.get_mitigation!(&1, [:threats, :assumptions]),
      id,
      workspace_id
    )
  end

  defp call_relationship(:link, "threat", threat, "assumption", assumption),
    do: Composer.add_assumption_to_threat(threat, assumption)

  defp call_relationship(:unlink, "threat", threat, "assumption", assumption),
    do: Composer.remove_assumption_from_threat(threat, assumption)

  defp call_relationship(:link, "threat", threat, "mitigation", mitigation),
    do: Composer.add_mitigation_to_threat(threat, mitigation)

  defp call_relationship(:unlink, "threat", threat, "mitigation", mitigation),
    do: Composer.remove_mitigation_from_threat(threat, mitigation)

  defp call_relationship(:link, "assumption", assumption, "threat", threat),
    do: Composer.add_threat_to_assumption(assumption, threat)

  defp call_relationship(:unlink, "assumption", assumption, "threat", threat),
    do: Composer.remove_threat_from_assumption(assumption, threat)

  defp call_relationship(:link, "assumption", assumption, "mitigation", mitigation),
    do: Composer.add_mitigation_to_assumption(assumption, mitigation)

  defp call_relationship(:unlink, "assumption", assumption, "mitigation", mitigation),
    do: Composer.remove_mitigation_from_assumption(assumption, mitigation)

  defp call_relationship(:link, "mitigation", mitigation, "threat", threat),
    do: Composer.add_threat_to_mitigation(mitigation, threat)

  defp call_relationship(:unlink, "mitigation", mitigation, "threat", threat),
    do: Composer.remove_threat_from_mitigation(mitigation, threat)

  defp call_relationship(:link, "mitigation", mitigation, "assumption", assumption),
    do: Composer.add_assumption_to_mitigation(mitigation, assumption)

  defp call_relationship(:unlink, "mitigation", mitigation, "assumption", assumption),
    do: Composer.remove_assumption_from_mitigation(mitigation, assumption)

  defp call_relationship(_action, from_type, _from, to_type, _to),
    do: {:error, "Unsupported relationship: #{from_type} -> #{to_type}"}
end
