defmodule Valentine.Composer.ReferencePacks do
  @moduledoc """
  Reference pack collections, entries, and workspace imports.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.ReferencePackItem
  alias Valentine.Composer.Assumptions
  alias Valentine.Composer.Mitigations
  alias Valentine.Composer.Threats

  @doc """
  Returns the list of reference_pack_items.

  ## Examples

      iex> list_reference_pack_items()
      [%ReferencePackItem{}, ...]

  """
  def list_reference_pack_items do
    Repo.all(ReferencePackItem)
  end

  def list_reference_pack_items_by_collection(collection_id, collection_type) do
    from(rp in ReferencePackItem,
      where: rp.collection_type == ^collection_type and rp.collection_id == ^collection_id
    )
    |> Repo.all()
  end

  def list_reference_packs() do
    # Ecto Query to extart reference packs from reference_pack_items by {:collection_type, :collection_id, collection_name} and count
    query =
      from rp in ReferencePackItem,
        group_by: [rp.collection_type, rp.collection_id, rp.collection_name],
        select: %{
          collection_type: rp.collection_type,
          collection_id: rp.collection_id,
          collection_name: rp.collection_name,
          count: count(rp.id)
        }

    Repo.all(query)
  end

  @doc """
  Gets a single reference_pack_item.

  Raises `Ecto.NoResultsError` if the ReferencePackItem does not exist.

  ## Examples

      iex> get_reference_pack_item!(123)
      %ReferencePackItem{}

      iex> get_reference_pack_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_reference_pack_item!(id), do: Repo.get!(ReferencePackItem, id)

  @doc """
  Creates a reference_pack_item.

  ## Examples

      iex> create_reference_pack_item(%{field: value})
      {:ok, %ReferencePackItem{}}

      iex> create_reference_pack_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_reference_pack_item(attrs \\ %{}) do
    %ReferencePackItem{}
    |> ReferencePackItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a reference_pack_item.

  ## Examples

      iex> update_reference_pack_item(reference_pack_item, %{field: new_value})
      {:ok, %ReferencePackItem{}}

      iex> update_reference_pack_item(reference_pack_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reference_pack_item(%ReferencePackItem{} = reference_pack_item, attrs) do
    reference_pack_item
    |> ReferencePackItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_reference_pack_collection(collection_id, collection_type) do
    Repo.delete_all(
      from(rp in ReferencePackItem,
        where: rp.collection_id == ^collection_id and rp.collection_type == ^collection_type
      )
    )
  end

  @doc """
  Deletes a reference_pack_item.

  ## Examples

      iex> delete_reference_pack_item(reference_pack_item)
      {:ok, %ReferencePackItem{}}

      iex> delete_reference_pack_item(reference_pack_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_reference_pack_item(%ReferencePackItem{} = reference_pack_item) do
    Repo.delete(reference_pack_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reference_pack_item changes.

  ## Examples

      iex> change_reference_pack_item(reference_pack_item)
      %Ecto.Changeset{data: %ReferencePackItem{}}

  """
  def change_reference_pack_item(
        %ReferencePackItem{} = reference_pack_item,
        attrs \\ %{}
      ) do
    ReferencePackItem.changeset(reference_pack_item, attrs)
  end

  def add_reference_pack_item_to_workspace(
        workspace_id,
        %ReferencePackItem{} = reference_pack_item
      ) do
    # Determin the type of the collection and then add the data of the reference pack item to that workspace with that type
    case reference_pack_item.collection_type do
      :assumption ->
        %{
          "workspace_id" => workspace_id
        }
        |> Map.merge(
          reference_pack_item.data
          |> Map.delete("mitigations")
          |> Map.delete("threats")
        )
        |> Assumptions.create_assumption()

      :threat ->
        %{
          "workspace_id" => workspace_id
        }
        |> Map.merge(
          reference_pack_item.data
          |> Map.delete("assumptions")
          |> Map.delete("mitigations")
          |> Map.delete("priority")
          |> Map.delete("status")
        )
        |> Threats.create_threat()

      :mitigation ->
        %{
          "workspace_id" => workspace_id
        }
        |> Map.merge(
          reference_pack_item.data
          |> Map.delete("assumptions")
          |> Map.delete("threats")
          |> Map.delete("status")
        )
        |> Mitigations.create_mitigation()

      _ ->
        {:error, "Invalid collection type"}
    end
  end
end
