defmodule Valentine.MCP.Tools.Workspace do
  import Valentine.MCP.ToolHelpers

  alias Valentine.Composer
  alias ValentineWeb.Workspace.Json, as: WorkspaceJson

  @export_preloads [
    :application_information,
    :architecture,
    :data_flow_diagram,
    assumptions: [:threats, :mitigations],
    mitigations: [:threats, :assumptions],
    threats: [:assumptions, :mitigations]
  ]

  def list_workspaces(_args, api_key) do
    api_key.owner
    |> Composer.list_workspaces_by_identity()
    |> ok_json()
  end

  def get_workspace(_args, api_key) do
    api_key.workspace_id
    |> Composer.get_workspace!()
    |> ok_json()
  end

  def create_workspace(args, api_key) do
    attrs =
      args
      |> normalize_attrs()
      |> Map.put("owner", api_key.owner)
      |> Map.put_new("permissions", %{})

    case Composer.create_workspace(attrs) do
      {:ok, workspace} -> ok_json(workspace)
      {:error, changeset} -> tool_error(Jason.encode!(format_changeset_errors(changeset)))
    end
  end

  def update_workspace(args, api_key) do
    workspace = Composer.get_workspace!(api_key.workspace_id)

    case Composer.update_workspace(workspace, normalize_attrs(args)) do
      {:ok, workspace} -> ok_json(workspace)
      {:error, changeset} -> tool_error(Jason.encode!(format_changeset_errors(changeset)))
    end
  end

  def export_workspace(_args, api_key) do
    workspace = Composer.get_workspace!(api_key.workspace_id, @export_preloads)
    ok_text(WorkspaceJson.serialize_workspace(workspace))
  end
end
