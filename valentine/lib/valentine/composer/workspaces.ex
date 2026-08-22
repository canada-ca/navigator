defmodule Valentine.Composer.Workspaces do
  @moduledoc """
  Workspace persistence, access, invitations, and permissions.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Workspace

  def permission_topic(workspace_id), do: "workspace_permissions:#{workspace_id}"

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
      where:
        w.owner == ^identity or
          fragment("? ->> ? IN ('read', 'write')", w.permissions, ^identity)
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

  def update_workspace(%Workspace{} = workspace, actor_identity, attrs) do
    with {:ok, current_workspace} <- authorize(workspace.id, actor_identity, :manage) do
      update_workspace(current_workspace, attrs)
    end
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
  def update_workspace_permissions(
        %Workspace{} = workspace,
        actor_identity,
        collaborator_identity,
        permission
      ) do
    workspace = get_workspace!(workspace.id)

    with :ok <- authorize_permission_update(workspace, actor_identity, collaborator_identity),
         {:ok, permissions} <- updated_permissions(workspace, collaborator_identity, permission),
         {:ok, workspace} <-
           workspace
           |> Workspace.permission_changeset(permissions)
           |> Repo.update() do
      Phoenix.PubSub.broadcast(
        Valentine.PubSub,
        permission_topic(workspace.id),
        {:workspace_permission_updated, workspace.id, collaborator_identity}
      )

      {:ok, workspace}
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

  def delete_workspace(%Workspace{} = workspace, actor_identity) do
    with {:ok, current_workspace} <- authorize(workspace.id, actor_identity, :manage) do
      delete_workspace(current_workspace)
    end
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

  def authorize(workspace_id, identity, capability)
      when capability in [:read, :write, :manage] do
    case Repo.get(Workspace, workspace_id) do
      nil ->
        {:error, :not_found}

      workspace ->
        permission = Workspace.check_workspace_permissions(workspace, identity)

        if permitted?(permission, capability) do
          {:ok, workspace}
        else
          {:error, :unauthorized}
        end
    end
  end

  def authorized?(workspace_id, identity, capability) do
    match?({:ok, %Workspace{}}, authorize(workspace_id, identity, capability))
  end

  defp permitted?(permission, :read), do: Workspace.can_read?(permission)
  defp permitted?(permission, :write), do: Workspace.can_write?(permission)
  defp permitted?(permission, :manage), do: Workspace.can_manage?(permission)

  defp authorize_permission_update(%Workspace{owner: owner}, owner, collaborator_identity)
       when owner != collaborator_identity,
       do: :ok

  defp authorize_permission_update(%Workspace{owner: owner}, owner, owner),
    do: {:error, :cannot_change_owner_permission}

  defp authorize_permission_update(%Workspace{}, _actor_identity, _collaborator_identity),
    do: {:error, :unauthorized}

  defp updated_permissions(workspace, collaborator_identity, "none") do
    {:ok, Map.delete(workspace.permissions, collaborator_identity)}
  end

  defp updated_permissions(workspace, collaborator_identity, permission) do
    if Workspace.valid_stored_permission?(permission) do
      {:ok, Map.put(workspace.permissions, collaborator_identity, permission)}
    else
      {:error, :invalid_permission}
    end
  end
end
