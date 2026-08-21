defmodule Valentine.Composer.QueryHelpers do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Valentine.Repo

  def apply_enum_filters(queryable, filters, schema_module) do
    Enum.reduce(filters, queryable, fn {field_name, selected}, query ->
      case schema_module.__schema__(:type, field_name) do
        {:array, _} ->
          apply_array_filter(query, field_name, selected)

        {:parameterized, _} ->
          apply_value_filter(query, field_name, selected)

        :string ->
          apply_value_filter(query, field_name, selected)

        _ ->
          query
      end
    end)
  end

  def get_workspace_entity!(schema, workspace_id, id, preload) do
    schema
    |> workspace_entity_query(workspace_id, id)
    |> Repo.one!()
    |> preload_workspace_entity(preload)
  end

  def get_workspace_entity(schema, workspace_id, id, preload) do
    schema
    |> workspace_entity_query(workspace_id, id)
    |> Repo.one()
    |> preload_workspace_entity(preload)
  end

  defp apply_array_filter(query, _field_name, selected) when selected in [nil, []], do: query

  defp apply_array_filter(query, field_name, [first | rest]) do
    query = where(query, [record], ^first in field(record, ^field_name))

    Enum.reduce(rest, query, fn selected, filtered_query ->
      or_where(filtered_query, [record], ^selected in field(record, ^field_name))
    end)
  end

  defp apply_value_filter(query, _field_name, selected) when selected in [nil, []], do: query

  defp apply_value_filter(query, field_name, selected) do
    where(query, [record], field(record, ^field_name) in ^selected)
  end

  defp workspace_entity_query(schema, workspace_id, id) do
    from(entity in schema,
      where: entity.workspace_id == ^workspace_id and entity.id == ^id
    )
  end

  defp preload_workspace_entity(nil, _preload), do: nil
  defp preload_workspace_entity(entity, nil), do: entity
  defp preload_workspace_entity(entity, preload), do: Repo.preload(entity, preload)
end
