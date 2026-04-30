defmodule Valentine.MCP.ToolHelpers do
  alias Ecto.Changeset

  def ok_json(data), do: {:ok, [%{type: "text", text: Jason.encode!(data)}]}

  def ok_text(text) when is_binary(text), do: {:ok, [%{type: "text", text: text}]}

  def tool_error(message) when is_binary(message), do: {:tool_error, message}

  def normalize_attrs(attrs) when is_map(attrs) do
    attrs
    |> Map.drop(["workspace_id", :workspace_id])
  end

  def format_error(%Changeset{} = changeset), do: format_changeset_errors(changeset)
  def format_error(message) when is_binary(message), do: message
  def format_error(_error), do: "Operation failed"

  def format_changeset_errors(changeset) do
    Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def ensure_workspace_entity(%{workspace_id: workspace_id} = entity, workspace_id),
    do: {:ok, entity}

  def ensure_workspace_entity(nil, _workspace_id), do: {:error, "Entity not found"}

  def ensure_workspace_entity(_entity, _workspace_id),
    do: {:error, "Entity not found in workspace"}

  def fetch_workspace_entity(fun, id, workspace_id) do
    fun.(id)
    |> ensure_workspace_entity(workspace_id)
  rescue
    Ecto.NoResultsError -> {:error, "Entity not found"}
  end

  def schema(properties, required \\ []) do
    %{
      type: "object",
      properties: properties,
      required: required,
      additionalProperties: false
    }
  end
end
