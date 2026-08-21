defmodule Valentine.MCP.Tools.Workspace do
  import Valentine.MCP.ToolHelpers

  alias Valentine.Composer.Workspaces
  alias ValentineWeb.Workspace.Json, as: WorkspaceJson

  @update_fields [
    "name",
    "cloud_profile",
    "cloud_profile_type",
    "cloud_vendors",
    "url",
    "max_threat_level"
  ]

  @export_preloads [
    :application_information,
    :architecture,
    :data_flow_diagram,
    assumptions: [:threats, :mitigations],
    mitigations: [:threats, :assumptions],
    threats: [:assumptions, :mitigations]
  ]

  def list_workspaces(_args, api_key) do
    workspace = Workspaces.get_workspace!(api_key.workspace_id)
    ok_json([workspace])
  end

  def get_workspace(_args, api_key) do
    api_key.workspace_id
    |> Workspaces.get_workspace!()
    |> ok_json()
  end

  def update_workspace(args, api_key) do
    workspace = Workspaces.get_workspace!(api_key.workspace_id)
    attrs = args |> normalize_attrs() |> Map.take(@update_fields)

    case Workspaces.update_workspace(workspace, attrs) do
      {:ok, workspace} -> ok_json(workspace)
      {:error, changeset} -> tool_error(Jason.encode!(format_changeset_errors(changeset)))
    end
  end

  def export_workspace(_args, api_key) do
    workspace = Workspaces.get_workspace!(api_key.workspace_id, @export_preloads)
    ok_text(WorkspaceJson.serialize_workspace(workspace))
  end
end
