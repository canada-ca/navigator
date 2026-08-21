defmodule Valentine.Composer.Workspaces do
  @moduledoc """
  Workspace persistence, access, invitations, and permissions.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Workspace

  @doc """
  Returns the list of workspaces.

  ## Examples

      iex> list_workspaces()
      [%Workspace{}, ...]

  """
  def list_workspaces do
    Repo.all(Workspace)
  end

  @doc """
  Returns the list of workspaces that a specific identity has permissions to access.

  ## Parameters
    * identity - The identity of the user to filter workspaces by

  ## Examples

      iex> list_workspaces_by_identity("some.owner@localhost")
      [%Workspace{}, ...]

      iex> list_workspaces_by_identity("some.collaborator@localhost")
      [%Workspace{}, ...]
  """

  def list_workspaces_by_identity(identity) do
    from(w in Workspace,
      where: w.owner == ^identity or fragment("? \\? ?", w.permissions, ^identity)
    )
    |> Repo.all()
  end

  @doc """
  Gets a single workspace.

  Raises `Ecto.NoResultsError` if the Workspace does not exist.

  ## Examples

      iex> get_workspace!(123)
      %Workspace{}

      iex> get_workspace!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workspace!(id, _preload \\ nil)

  def get_workspace!(id, preload) when is_list(preload) do
    Repo.get!(Workspace, id)
    |> Repo.preload(preload)
  end

  def get_workspace!(id, preload) when is_nil(preload), do: Repo.get!(Workspace, id)

  @doc """
  Creates a workspace.

  ## Examples

      iex> create_workspace(%{field: value})
      {:ok, %Workspace{}}

      iex> create_workspace(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workspace(attrs \\ %{}) do
    %Workspace{}
    |> Workspace.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workspace.

  ## Examples

      iex> update_workspace(workspace, %{field: new_value})
      {:ok, %Workspace{}}

      iex> update_workspace(workspace, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workspace(%Workspace{} = workspace, attrs) do
    workspace
    |> Workspace.changeset(attrs)
    |> Repo.update()
  end

  @doc """
    Updates workspace permissions.

    ## Parameters
      * workspace - The workspace to update
      * identity - The identity of the user to update permissions for
      * permission - The new permission level for the user

    ## Examples

        iex> update_workspace_permissions(workspace, "some.owner@localhost", "owner")
        %Workspace{permissions: %{"some.owner@localhost" => "owner"}}
  """
  def update_workspace_permissions(%Workspace{} = workspace, identity, permission) do
    case permission do
      "none" ->
        workspace
        |> Workspace.changeset(%{permissions: Map.delete(workspace.permissions, identity)})
        |> Repo.update()

      p ->
        workspace
        |> Workspace.changeset(%{permissions: Map.put(workspace.permissions, identity, p)})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a workspace.

  ## Examples

      iex> delete_workspace(workspace)
      {:ok, %Workspace{}}

      iex> delete_workspace(workspace)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workspace(%Workspace{} = workspace) do
    Repo.delete(workspace)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workspace changes.

  ## Examples

      iex> change_workspace(workspace)
      %Ecto.Changeset{data: %Workspace{}}

  """
  def change_workspace(%Workspace{} = workspace, attrs \\ %{}) do
    Workspace.changeset(workspace, attrs)
  end

  @doc """
  Checks if a user is the owner of the workspace or if their identity is in the permissions map. Returns the permission level if the user is the owner or has a permission level, otherwise returns nil.

  ## Examples

      iex> check_workspace_permissions(workspace_id, "some.owner@localhost")
      :owner

      iex> check_workspace_permissions(workspace_id, "some.collaborator@localhost")
      :write
  """
  def check_workspace_permissions(workspace_id, identity) do
    workspace = get_workspace!(workspace_id)
    Workspace.check_workspace_permissions(workspace, identity)
  end
end
