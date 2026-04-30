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

    case validate_dfd_attrs(attrs, dfd) do
      :ok ->
        case Composer.update_data_flow_diagram(dfd, attrs) do
          {:ok, dfd} ->
            DataFlowDiagram.put(dfd)
            ok_json(dfd_map(dfd))

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

  defp validate_node(id, %{"data" => %{} = data}) when is_binary(id) do
    cond do
      Map.get(data, "id") != id ->
        {:error, "DFD node #{id} data.id must match the node key"}

      !is_binary(Map.get(data, "label")) ->
        {:error, "DFD node #{id} must include a string data.label"}

      Map.get(data, "type") not in @node_types ->
        {:error, "DFD node #{id} has an unsupported data.type"}

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
end
