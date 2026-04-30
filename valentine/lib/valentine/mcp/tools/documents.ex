defmodule Valentine.MCP.Tools.Documents do
  import Valentine.MCP.ToolHelpers

  alias Valentine.Composer
  alias Valentine.Composer.DataFlowDiagram
  alias ValentineWeb.Workspace.Mermaid

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

    case Composer.update_data_flow_diagram(dfd, attrs) do
      {:ok, dfd} -> ok_json(dfd_map(dfd))
      {:error, changeset} -> tool_error(Jason.encode!(format_changeset_errors(changeset)))
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
end
