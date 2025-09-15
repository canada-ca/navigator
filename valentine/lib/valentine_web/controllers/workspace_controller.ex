defmodule ValentineWeb.WorkspaceController do
  use ValentineWeb, :controller

  alias Valentine.Composer

  def excel(conn, %{"workspace_id" => workspace_id}) do
    workspace = get_workspace(workspace_id)

    case ValentineWeb.Workspace.Excel.generate(workspace) do
      {:ok, {_filename, excel}} ->
        log(:info, get_session(conn, :user_id), "downloaded excel", workspace.id, "workspace")

        send_download(
          conn,
          {:binary, excel},
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          filename: "SRTM for #{workspace.name}.xlsx"
        )

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to generate Excel file: #{reason}"})
    end
  end

  def markdown(conn, %{"workspace_id" => workspace_id}) do
    workspace = get_workspace(workspace_id)
    markdown = ValentineWeb.Workspace.Markdown.generate(workspace)

    log(:info, get_session(conn, :user_id), "downloaded markdown", workspace.id, "workspace")

    send_download(
      conn,
      {:binary, markdown},
      content_type: "text/markdown",
      filename: "Threat model for #{workspace.name}.md"
    )
  end

  def export(conn, %{"workspace_id" => workspace_id}) do
    workspace = get_workspace(workspace_id)
    json = ValentineWeb.Workspace.Json.serialize_workspace(workspace)

    log(:info, get_session(conn, :user_id), "exported json", workspace.id, "workspace")

    send_download(
      conn,
      {:binary, json},
      content_type: "application/json",
      filename: "Workspace_#{workspace.name}.json"
    )
  end

  def export_assumptions(conn, %{"workspace_id" => workspace_id}) do
    workspace = get_workspace(workspace_id)

    assumptions = %{
      name: workspace.name,
      description: "Assumptions for #{workspace.name}",
      assumptions:
        ValentineWeb.Workspace.Json.serialize_assumptions(workspace.assumptions)
        |> Enum.map(fn assumption ->
          assumption
          |> Map.delete(:threats)
          |> Map.delete(:mitigations)
        end)
    }

    log(:info, get_session(conn, :user_id), "exported assumptions", workspace.id, "workspace")

    send_download(
      conn,
      {:binary, Jason.encode!(assumptions)},
      content_type: "application/json",
      filename: "Assumptions_#{workspace.name}_Reference_Pack.json"
    )
  end

  def export_mitigations(conn, %{"workspace_id" => workspace_id}) do
    workspace = get_workspace(workspace_id)

    mitigations = %{
      name: workspace.name,
      description: "Mitigations for #{workspace.name}",
      mitigations:
        ValentineWeb.Workspace.Json.serialize_mitigations(workspace.mitigations)
        |> Enum.map(fn mitigation ->
          mitigation
          |> Map.delete(:threats)
          |> Map.delete(:assumptions)
        end)
    }

    log(:info, get_session(conn, :user_id), "exported mitigations", workspace.id, "workspace")

    send_download(
      conn,
      {:binary, Jason.encode!(mitigations)},
      content_type: "application/json",
      filename: "Mitigations_#{workspace.name}_Reference_Pack.json"
    )
  end

  def export_threats(conn, %{"workspace_id" => workspace_id}) do
    workspace = get_workspace(workspace_id)

    threats = %{
      name: workspace.name,
      description: "Threats for #{workspace.name}",
      threats:
        ValentineWeb.Workspace.Json.serialize_threats(workspace.threats)
        |> Enum.map(fn threat ->
          threat
          |> Map.delete(:assumptions)
          |> Map.delete(:mitigations)
        end)
    }

    log(:info, get_session(conn, :user_id), "exported threats", workspace.id, "workspace")

    send_download(
      conn,
      {:binary, Jason.encode!(threats)},
      content_type: "application/json",
      filename: "Threats_#{workspace.name}_Reference_Pack.json"
    )
  end

  def export_dfd_mermaid(conn, %{"workspace_id" => workspace_id}) do
    workspace = get_workspace(workspace_id)
    mermaid_content = ValentineWeb.Workspace.Mermaid.generate_flowchart(workspace_id)

    log(:info, get_session(conn, :user_id), "exported dfd mermaid", workspace.id, "workspace")

    send_download(
      conn,
      {:binary, mermaid_content},
      content_type: "text/plain",
      filename: "DFD_#{workspace.name}.mmd"
    )
  end

  defp get_workspace(id) do
    Composer.get_workspace!(id, [
      :application_information,
      :architecture,
      :data_flow_diagram,
      mitigations: [:assumptions, :threats],
      threats: [:assumptions, :mitigations],
      assumptions: [:threats, :mitigations]
    ])
  end
end
