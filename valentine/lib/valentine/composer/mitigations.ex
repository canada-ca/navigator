defmodule Valentine.Composer.Mitigations do
  @moduledoc """
  Mitigation persistence and queries.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.QueryHelpers

  @doc """
  Returns the list of mitigations.

  ## Examples

      iex> list_mitigations()
      [%Mitigation{}, ...]

  """
  def list_mitigations do
    Repo.all(Mitigation)
  end

  @doc """
  Filters mitigations based on enum field values.

  Takes a queryable and a map of filters where keys are field names and values are selected enum values.
  Handles both array and parameterized enum fields.

  ## Examples

      iex> filters = %{severity: ["HIGH", "CRITICAL"], status: ["OPEN"]}
      iex> list_mitigations_with_enum_filters(Mitigation, filters)
      [%Mitigation{severity: "HIGH", status: "OPEN"}, ...]

  """
  def list_mitigations_with_enum_filters(m, filters) do
    QueryHelpers.apply_enum_filters(m, filters, Mitigation)
  end

  @doc """
  Returns the list of mitigations for a specific workspace.

  ## Parameters

    * workspace_id - The UUID of the workspace to filter mitigations by

  ## Examples

      iex> list_mitigations_by_workspace("123e4567-e89b-12d3-a456-426614174000")
      [%Mitigation{}, ...]

      iex> list_mitigations_by_workspace("nonexistent-id")
      []
  """
  def list_mitigations_by_workspace(workspace_id, enum_filters \\ %{}) do
    from(t in Mitigation, where: t.workspace_id == ^workspace_id)
    |> list_mitigations_with_enum_filters(enum_filters)
    |> order_by([t], desc: t.numeric_id)
    |> Repo.all()
  end

  @doc """
  Gets a single mitigation.

  Raises `Ecto.NoResultsError` if the Mitigation does not exist.

  ## Examples

      iex> get_mitigation!(123)
      %Mitigation{}

      iex> get_mitigation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mitigation!(id, _preload \\ nil)

  def get_mitigation!(id, preload) when is_list(preload) do
    Repo.get!(Mitigation, id)
    |> Repo.preload(preload)
  end

  def get_mitigation!(id, preload) when is_nil(preload), do: Repo.get!(Mitigation, id)

  def get_mitigation_for_workspace!(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity!(Mitigation, workspace_id, id, preload)
  end

  def get_mitigation_for_workspace(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity(Mitigation, workspace_id, id, preload)
  end

  @doc """
  Creates a mitigation.

  ## Examples

      iex> create_mitigation(%{field: value})
      {:ok, %Mitigation{}}

      iex> create_mitigation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_mitigation(attrs \\ %{}) do
    %Mitigation{}
    |> Mitigation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a mitigation.

  ## Examples

      iex> update_mitigation(mitigation, %{field: new_value})
      {:ok, %Mitigation{}}

      iex> update_mitigation(mitigation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mitigation(%Mitigation{} = mitigation, attrs) do
    mitigation
    |> Mitigation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a mitigation.

  ## Examples

      iex> delete_mitigation(mitigation)
      {:ok, %Mitigation{}}

      iex> delete_mitigation(mitigation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mitigation(%Mitigation{} = mitigation) do
    Repo.delete(mitigation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mitigation changes.

  ## Examples

      iex> change_mitigation(mitigation)
      %Ecto.Changeset{data: %Mitigation{}}

  """
  def change_mitigation(%Mitigation{} = mitigation, attrs \\ %{}) do
    Mitigation.changeset(mitigation, attrs)
  end
end
