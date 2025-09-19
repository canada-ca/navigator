defmodule Valentine.Composer.BrainstormItems do
  @moduledoc """
  The BrainstormItems context for managing brainstorm board items.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo
  alias Valentine.Composer.BrainstormItem

  @doc """
  Returns the list of brainstorm items for a workspace.

  ## Examples

      iex> list_brainstorm_items(workspace_id)
      [%BrainstormItem{}, ...]

  """
  def list_brainstorm_items(workspace_id, filters \\ %{}) do
    workspace_id
    |> base_query()
    |> apply_filters(filters)
    |> order_by_position()
    |> Repo.all()
  end

  @doc """
  Returns brainstorm items grouped by type for board display.

  ## Examples

      iex> list_brainstorm_items_by_type(workspace_id)
      %{threat: [%BrainstormItem{}], assumption: [...]}

  """
  def list_brainstorm_items_by_type(workspace_id, filters \\ %{}) do
    items = list_brainstorm_items(workspace_id, filters)
    Enum.group_by(items, & &1.type)
  end

  @doc """
  Returns items in a specific cluster.

  ## Examples

      iex> list_cluster_items(workspace_id, "cluster_123")
      [%BrainstormItem{}, ...]

  """
  def list_cluster_items(workspace_id, cluster_key) do
    workspace_id
    |> base_query()
    |> where([bi], bi.cluster_key == ^cluster_key)
    |> order_by_position()
    |> Repo.all()
  end

  @doc """
  Returns items that are candidates for threat assembly (clustered or candidate status).

  ## Examples

      iex> list_assembly_candidates(workspace_id, "cluster_123")
      [%BrainstormItem{}, ...]

  """
  def list_assembly_candidates(workspace_id, cluster_key \\ nil) do
    query = 
      workspace_id
      |> base_query()
      |> where([bi], bi.status in [:clustered, :candidate])

    query = if cluster_key, do: where(query, [bi], bi.cluster_key == ^cluster_key), else: query

    query
    |> order_by_position()
    |> Repo.all()
  end

  @doc """
  Returns the backlog of items (not used or archived).

  ## Examples

      iex> list_backlog_items(workspace_id)
      [%BrainstormItem{}, ...]

  """
  def list_backlog_items(workspace_id) do
    workspace_id
    |> base_query()
    |> where([bi], bi.status not in [:used, :archived])
    |> order_by([bi], bi.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single brainstorm item.

  Raises `Ecto.NoResultsError` if the BrainstormItem does not exist.

  ## Examples

      iex> get_brainstorm_item!(123)
      %BrainstormItem{}

      iex> get_brainstorm_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_brainstorm_item!(id), do: Repo.get!(BrainstormItem, id)

  @doc """
  Gets a single brainstorm item by id and workspace.

  Returns `nil` if the BrainstormItem does not exist or doesn't belong to the workspace.

  ## Examples

      iex> get_brainstorm_item(workspace_id, item_id)
      %BrainstormItem{}

      iex> get_brainstorm_item(workspace_id, invalid_id)
      nil

  """
  def get_brainstorm_item(workspace_id, item_id) do
    workspace_id
    |> base_query()
    |> where([bi], bi.id == ^item_id)
    |> Repo.one()
  end

  @doc """
  Creates a brainstorm item.

  ## Examples

      iex> create_brainstorm_item(%{field: value})
      {:ok, %BrainstormItem{}}

      iex> create_brainstorm_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_brainstorm_item(attrs \\ %{}) do
    %BrainstormItem{}
    |> BrainstormItem.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, item} ->
        emit_telemetry(:created, item)
        {:ok, item}
      error ->
        error
    end
  end

  @doc """
  Updates a brainstorm item.

  ## Examples

      iex> update_brainstorm_item(brainstorm_item, %{field: new_value})
      {:ok, %BrainstormItem{}}

      iex> update_brainstorm_item(brainstorm_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_brainstorm_item(%BrainstormItem{} = brainstorm_item, attrs) do
    old_status = brainstorm_item.status

    brainstorm_item
    |> BrainstormItem.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_item} ->
        emit_telemetry(:updated, updated_item)
        
        if old_status != updated_item.status do
          emit_telemetry(:status_changed, updated_item, %{old_status: old_status, new_status: updated_item.status})
        end
        
        {:ok, updated_item}
      error ->
        error
    end
  end

  @doc """
  Assigns a brainstorm item to a cluster.

  ## Examples

      iex> assign_to_cluster(brainstorm_item, "cluster_123")
      {:ok, %BrainstormItem{}}

  """
  def assign_to_cluster(%BrainstormItem{} = brainstorm_item, cluster_key) do
    brainstorm_item
    |> BrainstormItem.assign_to_cluster(cluster_key)
    |> Repo.update()
    |> case do
      {:ok, updated_item} ->
        emit_telemetry(:cluster_assigned, updated_item)
        {:ok, updated_item}
      error ->
        error
    end
  end

  @doc """
  Updates the position of a brainstorm item.

  ## Examples

      iex> update_position(brainstorm_item, 100)
      {:ok, %BrainstormItem{}}

  """
  def update_position(%BrainstormItem{} = brainstorm_item, position) do
    brainstorm_item
    |> BrainstormItem.update_position(position)
    |> Repo.update()
  end

  @doc """
  Marks a brainstorm item as used in a threat.

  ## Examples

      iex> mark_used_in_threat(brainstorm_item, 123)
      {:ok, %BrainstormItem{}}

  """
  def mark_used_in_threat(%BrainstormItem{} = brainstorm_item, threat_id) do
    case BrainstormItem.mark_used_in_threat(brainstorm_item, threat_id) do
      %Ecto.Changeset{} = changeset ->
        Repo.update(changeset)
      {:ok, item} ->
        {:ok, item}
    end
  end

  @doc """
  Removes a threat ID from a brainstorm item's used_in_threat_ids.

  ## Examples

      iex> unmark_used_in_threat(brainstorm_item, 123)
      {:ok, %BrainstormItem{}}

  """
  def unmark_used_in_threat(%BrainstormItem{} = brainstorm_item, threat_id) do
    brainstorm_item
    |> BrainstormItem.unmark_used_in_threat(threat_id)
    |> Repo.update()
  end

  @doc """
  Deletes a brainstorm item.

  ## Examples

      iex> delete_brainstorm_item(brainstorm_item)
      {:ok, %BrainstormItem{}}

      iex> delete_brainstorm_item(brainstorm_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_brainstorm_item(%BrainstormItem{} = brainstorm_item) do
    Repo.delete(brainstorm_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking brainstorm item changes.

  ## Examples

      iex> change_brainstorm_item(brainstorm_item)
      %Ecto.Changeset{data: %BrainstormItem{}}

  """
  def change_brainstorm_item(%BrainstormItem{} = brainstorm_item, attrs \\ %{}) do
    BrainstormItem.changeset(brainstorm_item, attrs)
  end

  @doc """
  Returns funnel metrics for conversion tracking.

  ## Examples

      iex> get_funnel_metrics(workspace_id)
      %{draft: 10, clustered: 5, candidate: 3, used: 2, archived: 1}

  """
  def get_funnel_metrics(workspace_id) do
    workspace_id
    |> base_query()
    |> group_by([bi], bi.status)
    |> select([bi], {bi.status, count(bi.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Returns items by type for analytics.

  ## Examples

      iex> get_type_metrics(workspace_id)
      %{threat: 10, assumption: 5, mitigation: 3}

  """
  def get_type_metrics(workspace_id) do
    workspace_id
    |> base_query()
    |> group_by([bi], bi.type)
    |> select([bi], {bi.type, count(bi.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  # Private functions

  defp base_query(workspace_id) do
    from(bi in BrainstormItem, where: bi.workspace_id == ^workspace_id)
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, &apply_filter/2)
  end

  defp apply_filter({:type, type}, query) when not is_nil(type) do
    where(query, [bi], bi.type == ^type)
  end

  defp apply_filter({:status, status}, query) when not is_nil(status) do
    where(query, [bi], bi.status == ^status)
  end

  defp apply_filter({:cluster_key, cluster_key}, query) when not is_nil(cluster_key) do
    where(query, [bi], bi.cluster_key == ^cluster_key)
  end

  defp apply_filter(_, query), do: query

  defp order_by_position(query) do
    order_by(query, [bi], [asc: bi.position, asc: bi.inserted_at])
  end

  # Telemetry events

  defp emit_telemetry(event, item, metadata \\ %{}) do
    :telemetry.execute(
      [:brainstorm, :item, event],
      %{count: 1},
      Map.merge(metadata, %{
        workspace_id: item.workspace_id,
        type: item.type,
        status: item.status
      })
    )
  end
end