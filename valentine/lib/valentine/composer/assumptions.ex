defmodule Valentine.Composer.Assumptions do
  @moduledoc """
  Assumption persistence and queries.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Assumption
  alias Valentine.Composer.QueryHelpers

  @doc """
  Returns the list of assumptions.

  ## Examples

      iex> list_assumptions()
      [%Assumption{}, ...]

  """
  def list_assumptions do
    Repo.all(Assumption)
  end

  @doc """
  Filters assumptions based on enum field values.

  Takes a queryable and a map of filters where keys are field names and values are selected enum values.
  Handles both array and parameterized enum fields.

  ## Examples

      iex> filters = %{severity: ["HIGH", "CRITICAL"], status: ["OPEN"]}
      iex> list_assumptions_with_enum_filters(Assumption, filters)
      [%Assumption{severity: "HIGH", status: "OPEN"}, ...]

  """
  def list_assumptions_with_enum_filters(m, filters) do
    QueryHelpers.apply_enum_filters(m, filters, Assumption)
  end

  @doc """
  Returns the list of assumptions for a specific workspace.

  ## Parameters

    * workspace_id - The UUID of the workspace to filter assumptions by

  ## Examples

      iex> list_assumptions_by_workspace("123e4567-e89b-12d3-a456-426614174000")
      [%Assumption{}, ...]

      iex> list_assumptions_by_workspace("nonexistent-id")
      []
  """
  def list_assumptions_by_workspace(workspace_id, enum_filters \\ %{}) do
    from(t in Assumption, where: t.workspace_id == ^workspace_id)
    |> list_assumptions_with_enum_filters(enum_filters)
    |> order_by([t], desc: t.numeric_id)
    |> Repo.all()
  end

  @doc """
  Gets a single assumption.

  Raises `Ecto.NoResultsError` if the Assumption does not exist.

  ## Examples

      iex> get_assumption!(123)
      %Assumption{}

      iex> get_assumption!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assumption!(id, _preload \\ nil)

  def get_assumption!(id, preload) when is_list(preload) do
    Repo.get!(Assumption, id)
    |> Repo.preload(preload)
  end

  def get_assumption!(id, preload) when is_nil(preload), do: Repo.get!(Assumption, id)

  def get_assumption_for_workspace!(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity!(Assumption, workspace_id, id, preload)
  end

  def get_assumption_for_workspace(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity(Assumption, workspace_id, id, preload)
  end

  @doc """
  Creates a assumption.

  ## Examples

      iex> create_assumption(%{field: value})
      {:ok, %Assumption{}}

      iex> create_assumption(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assumption(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:assumption, fn _ ->
      %Assumption{}
      |> Assumption.changeset(attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{assumption: assumption}} -> {:ok, assumption}
      {:error, :assumption, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates a assumption.

  ## Examples

      iex> update_assumption(assumption, %{field: new_value})
      {:ok, %Assumption{}}

      iex> update_assumption(assumption, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assumption(%Assumption{} = assumption, attrs) do
    assumption
    |> Assumption.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a assumption.

  ## Examples

      iex> delete_assumption(assumption)
      {:ok, %Assumption{}}

      iex> delete_assumption(assumption)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assumption(%Assumption{} = assumption) do
    Repo.delete(assumption)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assumption changes.

  ## Examples

      iex> change_assumption(assumption)
      %Ecto.Changeset{data: %Assumption{}}

  """
  def change_assumption(%Assumption{} = assumption, attrs \\ %{}) do
    Assumption.changeset(assumption, attrs)
  end
end
