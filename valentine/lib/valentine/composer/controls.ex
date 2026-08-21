defmodule Valentine.Composer.Controls do
  @moduledoc """
  Security control persistence, filtering, and ordering.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Control

  @doc """
  Returns the list of controls.

  ## Examples

      iex> list_controls()
      [%Control{}, ...]

  """
  def list_controls do
    # Get all controls and order them by their nist_id
    from(c in Control)
    |> sort_hierarchical_strings(:nist_id)
    |> Repo.all()
  end

  def list_controls_by_filters(filters) when is_map(filters) do
    tags = Map.get(filters, :tags, [])
    classes = Map.get(filters, :classes, [])
    nist_families = Map.get(filters, :nist_families, [])

    from(c in Control)
    |> filter_controls_by_tag(tags)
    |> filter_controls_by_class(classes)
    |> filter_controls_by_nist_family(nist_families)
    |> sort_hierarchical_strings(:nist_id)
    |> Repo.all()
  end

  defp filter_controls_by_tag(query, tags) when tags == [] or is_nil(tags), do: query

  defp filter_controls_by_tag(query, tags) do
    from(c in query, where: fragment("?::text[] <@ ?::text[]", ^tags, c.tags))
  end

  defp filter_controls_by_class(query, classes) when classes == [] or is_nil(classes), do: query

  defp filter_controls_by_class(query, classes) do
    from(c in query, where: c.class in ^classes)
  end

  defp filter_controls_by_nist_family(query, nist_families)
       when nist_families == [] or is_nil(nist_families),
       do: query

  defp filter_controls_by_nist_family(query, nist_families) do
    patterns = Enum.map(nist_families, &"#{&1}-%")
    from(c in query, where: fragment("? LIKE ANY(?::text[])", c.nist_id, ^patterns))
  end

  @spec sort_hierarchical_strings(any(), atom()) :: Ecto.Query.t()
  def sort_hierarchical_strings(query, field) do
    from record in query,
      order_by:
        fragment(
          """
          split_part(?, '-', 1),
          CASE
            WHEN split_part(split_part(?, '-', 2), '.', 1) ~ '^[0-9]+$'
            THEN CAST(split_part(split_part(?, '-', 2), '.', 1) AS INTEGER)
            ELSE 0
          END,
          CASE
            WHEN split_part(split_part(?, '-', 2), '.', 2) ~ '^[0-9]+$'
            THEN CAST(split_part(split_part(?, '-', 2), '.', 2) AS INTEGER)
            ELSE 0
          END
          """,
          field(record, ^field),
          field(record, ^field),
          field(record, ^field),
          field(record, ^field),
          field(record, ^field)
        )
  end

  def list_control_families do
    from(c in Control)
    |> select([c], fragment("DISTINCT split_part(?, '-', 1)", c.nist_id))
    |> order_by([c], fragment("split_part(?, '-', 1)", c.nist_id))
    |> Repo.all()
  end

  def list_controls_in_families(families) do
    from(c in Control)
    |> filter_controls_by_nist_family(families)
    |> sort_hierarchical_strings(:nist_id)
    |> Repo.all()
  end

  @doc """
  Gets a single control.

  Raises `Ecto.NoResultsError` if the Control does not exist.

  ## Examples

      iex> get_control!(123)
      %Control{}

      iex> get_control!(456)
      ** (Ecto.NoResultsError)

  """
  def get_control!(id), do: Repo.get!(Control, id)

  def get_control_by_nist_id(nil), do: nil

  def get_control_by_nist_id(nist_id) do
    Repo.get_by(Control, nist_id: nist_id)
  end

  @doc """
  Creates a control.

  ## Examples

      iex> create_control(%{field: value})
      {:ok, %Control{}}

      iex> create_control(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_control(attrs \\ %{}) do
    %Control{}
    |> Control.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a control.

  ## Examples

      iex> update_control(control, %{field: new_value})
      {:ok, %Control{}}

      iex> update_control(control, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_control(%Control{} = control, attrs) do
    control
    |> Control.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a control.

  ## Examples

      iex> delete_control(control)
      {:ok, %Control{}}

      iex> delete_control(control)
      {:error, %Ecto.Changeset{}}

  """
  def delete_control(%Control{} = control) do
    Repo.delete(control)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking control changes.

  ## Examples

      iex> change_control(control)
      %Ecto.Changeset{data: %Control{}}

  """
  def change_control(
        %Control{} = control,
        attrs \\ %{}
      ) do
    Control.changeset(control, attrs)
  end
end
