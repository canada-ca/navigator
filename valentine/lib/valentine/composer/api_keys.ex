defmodule Valentine.Composer.ApiKeys do
  @moduledoc """
  Workspace API key lifecycle and verification data.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.ApiKey
  alias Valentine.Composer.Workspace
  alias Valentine.Composer.QueryHelpers

  @doc """
  Returns the list of api_keys.

  ## Examples

      iex> list_api_keys()
      [%ApiKey{}, ...]

  """
  def list_api_keys do
    Repo.all(ApiKey)
  end

  @doc """
  Returns the list of api_keys for a specific workspace.

  ## Parameters

    * workspace_id - The UUID of the workspace to filter API keys by

  ## Examples

      iex> list_api_keys
      [%ApiKey{}, ...]

  """

  def list_api_keys_by_workspace(workspace_id) do
    from(a in ApiKey, where: a.workspace_id == ^workspace_id)
    |> Repo.all()
  end

  @doc """
  Gets a single api_key.

  Raises `Ecto.NoResultsError` if the ApiKey does not exist.

  ## Examples

      iex> get_api_key(123)
      %ApiKey{}

      iex> get_api_key(456)
      ** (Ecto.NoResultsError)

  """
  def get_api_key(id), do: Repo.get(ApiKey, id)

  def get_api_key_for_workspace(workspace_id, id) do
    QueryHelpers.get_workspace_entity(ApiKey, workspace_id, id, nil)
  end

  @doc """
  Creates a api_key.

  ## Examples

      iex> create_api_key(%{field: value})
      {:ok, %ApiKey{}}

      iex> create_api_key(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_api_key(attrs \\ %{}) do
    %ApiKey{}
    |> ApiKey.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, api_key} ->
        api_key
        |> ApiKey.generate_key()
        |> Ecto.Changeset.change()
        |> Repo.update()

      error ->
        error
    end
  end

  @doc """
  Creates an API key scoped to a workspace owned by the given identity.

  Only the label is accepted from `attrs`. The workspace, owner, and initial
  status are derived from trusted server-side values.
  """
  def create_api_key_for_workspace(
        %Workspace{owner: owner} = workspace,
        owner,
        attrs
      )
      when is_binary(owner) and is_map(attrs) do
    create_api_key(%{
      label: Map.get(attrs, "label", Map.get(attrs, :label)),
      owner: owner,
      status: :active,
      workspace_id: workspace.id
    })
  end

  def create_api_key_for_workspace(%Workspace{}, _identity, _attrs),
    do: {:error, :unauthorized}

  @doc """
  Updates a api_key.

  ## Examples

      iex> update_api_key(api_key, %{field: new_value})
      {:ok, %ApiKey{}}

      iex> update_api_key(api_key, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_api_key(%ApiKey{} = api_key, attrs) do
    api_key
    |> ApiKey.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a api_key.

  ## Examples

      iex> delete_api_key(api_key)
      {:ok, %ApiKey{}}

      iex> delete_api_key(api_key)
      {:error, %Ecto.Changeset{}}

  """
  def delete_api_key(%ApiKey{} = api_key) do
    Repo.delete(api_key)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking api_key changes.

  ## Examples

      iex> change_api_key(api_key)
      %Ecto.Changeset{data: %ApiKey{}}

  """
  def change_api_key(
        %ApiKey{} = api_key,
        attrs \\ %{}
      ) do
    ApiKey.changeset(api_key, attrs)
  end
end
