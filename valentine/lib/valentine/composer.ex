defmodule Valentine.Composer do
  @moduledoc """
  The Composer context.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Workspace
  alias Valentine.Composer.Assumption
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.Threat
  alias Valentine.Composer.Evidence
  alias Valentine.Composer.ApplicationInformation
  alias Valentine.Composer.DataFlowDiagram
  alias Valentine.Composer.Architecture
  alias Valentine.Composer.ReferencePackItem
  alias Valentine.Composer.Control
  alias Valentine.Composer.User
  alias Valentine.Composer.ApiKey
  alias Valentine.Composer.BrainstormItem

  alias Valentine.Composer.AssumptionThreat
  alias Valentine.Composer.AssumptionMitigation
  alias Valentine.Composer.MitigationThreat
  alias Valentine.Composer.EvidenceAssumption
  alias Valentine.Composer.EvidenceThreat
  alias Valentine.Composer.EvidenceMitigation

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
      * indentity - The identity of the user to update permissions for
      * permission - The new permission level for the user

    ## Examples

        iex> update_workspace_permissions(workspace, "some.owner@localhost", "owner")
        %Workspace{permissions: %{"some.owner@localhost" => "owner"}}
  """
  def update_workspace_permissions(%Workspace{} = workspace, indentity, permission) do
    case permission do
      "none" ->
        workspace
        |> Workspace.changeset(%{permissions: Map.delete(workspace.permissions, indentity)})
        |> Repo.update()

      p ->
        workspace
        |> Workspace.changeset(%{permissions: Map.put(workspace.permissions, indentity, p)})
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

  @doc """
  Returns the list of threats.

  ## Examples

      iex> list_threats()
      [%Threat{}, ...]

  """
  def list_threats do
    Repo.all(Threat)
  end

  @doc """
  Filters threats based on enum field values.

  Takes a queryable and a map of filters where keys are field names and values are selected enum values.
  Handles both array and parameterized enum fields.

  ## Examples

      iex> filters = %{severity: ["HIGH", "CRITICAL"], status: ["OPEN"]}
      iex> list_threats_with_enum_filters(Threat, filters)
      [%Threat{severity: "HIGH", status: "OPEN"}, ...]

  """
  def list_threats_with_enum_filters(m, filters) do
    Enum.reduce(filters, m, fn {f, selected}, queryable ->
      case Threat.__schema__(:type, f) do
        {:array, _} ->
          if is_nil(selected) || selected == [] do
            queryable
          else
            [first | rest] = selected
            query = where(queryable, [m], ^first in field(m, ^f))

            Enum.reduce(rest, query, fn s, q ->
              or_where(q, [m], ^s in field(m, ^f))
            end)
          end

        {:parameterized, _} ->
          if is_nil(selected) || selected == [] do
            queryable
          else
            where(queryable, [m], field(m, ^f) in ^selected)
          end
      end
    end)
  end

  def list_threats_by_ids(ids) do
    from(t in Threat, where: t.id in ^ids)
    |> Repo.all()
  end

  @doc """
  Returns the list of threats for a specific workspace.

  ## Parameters

    * workspace_id - The UUID of the workspace to filter threats by

  ## Examples

      iex> list_threats_by_workspace("123e4567-e89b-12d3-a456-426614174000")
      [%Threat{}, ...]

      iex> list_threats_by_workspace("nonexistent-id")
      []
  """
  def list_threats_by_workspace(workspace_id, enum_filters \\ %{}) do
    from(t in Threat, where: t.workspace_id == ^workspace_id)
    |> list_threats_with_enum_filters(enum_filters)
    |> order_by([t], desc: t.numeric_id)
    |> preload([:assumptions, :mitigations])
    |> Repo.all()
  end

  @doc """
  Gets a single threat.

  Raises `Ecto.NoResultsError` if the Threat does not exist.

  ## Examples

      iex> get_threat!(123)
      %Threat{}

      iex> get_threat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_threat!(id, _preload \\ nil)

  def get_threat!(id, preload) when is_list(preload) do
    Repo.get!(Threat, id)
    |> Repo.preload(preload)
  end

  def get_threat!(id, preload) when is_nil(preload), do: Repo.get!(Threat, id)

  @doc """
  Creates a threat.

  ## Examples

      iex> create_threat(%{field: value})
      {:ok, %Threat{}}

      iex> create_threat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_threat(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:threat, fn _ ->
      %Threat{}
      |> Threat.changeset(attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{threat: threat}} -> {:ok, threat}
      {:error, :threat, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates a threat.

  ## Examples

      iex> update_threat(threat, %{field: new_value})
      {:ok, %Threat{}}

      iex> update_threat(threat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_threat(%Threat{} = threat, attrs) do
    threat
    |> Threat.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a threat.

  ## Examples

      iex> delete_threat(threat)
      {:ok, %Threat{}}

      iex> delete_threat(threat)
      {:error, %Ecto.Changeset{}}

  """
  def delete_threat(%Threat{} = threat) do
    Repo.delete(threat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking threat changes.

  ## Examples

      iex> change_threat(threat)
      %Ecto.Changeset{data: %Threat{}}

  """
  def change_threat(%Threat{} = threat, attrs \\ %{}) do
    Threat.changeset(threat, attrs)
  end

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
    Enum.reduce(filters, m, fn {f, selected}, queryable ->
      case Assumption.__schema__(:type, f) do
        {:array, _} ->
          if is_nil(selected) || selected == [] do
            queryable
          else
            [first | rest] = selected
            query = where(queryable, [m], ^first in field(m, ^f))

            Enum.reduce(rest, query, fn s, q ->
              or_where(q, [m], ^s in field(m, ^f))
            end)
          end

        {:parameterized, _} ->
          if is_nil(selected) || selected == [] do
            queryable
          else
            where(queryable, [m], field(m, ^f) in ^selected)
          end
      end
    end)
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
    Enum.reduce(filters, m, fn {f, selected}, queryable ->
      case Mitigation.__schema__(:type, f) do
        {:array, _} ->
          if is_nil(selected) || selected == [] do
            queryable
          else
            [first | rest] = selected
            query = where(queryable, [m], ^first in field(m, ^f))

            Enum.reduce(rest, query, fn s, q ->
              or_where(q, [m], ^s in field(m, ^f))
            end)
          end

        {:parameterized, _} ->
          if is_nil(selected) || selected == [] do
            queryable
          else
            where(queryable, [m], field(m, ^f) in ^selected)
          end
      end
    end)
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

  @doc """
  Adds an assumption to an existing threat model.

  This function associates a security assumption with a specific threat,
  helping document the conditions under which the threat analysis remains valid.

  ## Parameters
    - threat: The threat structure to which the assumption will be added
    - assumption: The security assumption to be associated with the threat

  ## Returns
    Updated threat structure with the new assumption added

  ## Examples

      iex> add_assumption_to_threat(threat, assumption)
      %Threat{assumptions: [assumption], ...}

  """
  def add_assumption_to_threat(%Threat{} = threat, %Assumption{} = assumption) do
    %AssumptionThreat{assumption_id: assumption.id, threat_id: threat.id}
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, threat |> Repo.preload(:assumptions, force: true)}
      {:error, _} -> {:error, threat}
    end
  end

  @doc """
  Removes a specific assumption from a threat model.

  This function removes an existing security assumption from a threat,
  maintaining the threat model's accuracy when assumptions no longer apply.

  ## Parameters
    - threat: The threat structure from which the assumption will be removed
    - assumption: The security assumption to be removed

  ## Returns
    Updated threat structure with the specified assumption removed

  ## Examples

      iex> remove_assumption_from_threat(threat, assumption)
      %Threat{assumptions: [], ...}

  """
  def remove_assumption_from_threat(%Threat{} = threat, %Assumption{} = assumption) do
    Repo.delete_all(
      from(at in AssumptionThreat,
        where: at.assumption_id == ^assumption.id and at.threat_id == ^threat.id
      )
    )
    |> case do
      {1, nil} -> {:ok, threat |> Repo.preload(:assumptions, force: true)}
      {:error, _} -> {:error, threat}
    end
  end

  @doc """
  Adds an mitigation to an existing threat model.

  This function associates a security mitigation with a specific threat,
  helping document the conditions under which the threat analysis remains valid.

  ## Parameters
    - threat: The threat structure to which the mitigation will be added
    - mitigation: The security mitigation to be associated with the threat

  ## Returns
    Updated threat structure with the new mitigation added

  ## Examples

      iex> add_mitigation_to_threat(threat, mitigation)
      %Threat{mitigations: [mitigation], ...}

  """
  def add_mitigation_to_threat(%Threat{} = threat, %Mitigation{} = mitigation) do
    %MitigationThreat{mitigation_id: mitigation.id, threat_id: threat.id}
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, threat |> Repo.preload(:mitigations, force: true)}
      {:error, _} -> {:error, threat}
    end
  end

  @doc """
  Removes a specific mitigation from a threat model.

  This function removes an existing security mitigation from a threat,
  maintaining the threat model's accuracy when mitigations no longer apply.

  ## Parameters
    - threat: The threat structure from which the mitigation will be removed
    - mitigation: The security mitigation to be removed

  ## Returns
    Updated threat structure with the specified mitigation removed

  ## Examples

      iex> remove_mitigation_from_threat(threat, mitigation)
      %Threat{mitigations: [], ...}

  """
  def remove_mitigation_from_threat(%Threat{} = threat, %Mitigation{} = mitigation) do
    Repo.delete_all(
      from(at in MitigationThreat,
        where: at.mitigation_id == ^mitigation.id and at.threat_id == ^threat.id
      )
    )
    |> case do
      {1, nil} -> {:ok, threat |> Repo.preload(:mitigations, force: true)}
      {:error, _} -> {:error, threat}
    end
  end

  def add_threat_to_assumption(%Assumption{} = assumption, %Threat{} = threat) do
    %AssumptionThreat{assumption_id: assumption.id, threat_id: threat.id}
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, assumption |> Repo.preload(:threats, force: true)}
      {:error, _} -> {:error, assumption}
    end
  end

  def remove_threat_from_assumption(%Assumption{} = assumption, %Threat{} = threat) do
    Repo.delete_all(
      from(at in AssumptionThreat,
        where: at.assumption_id == ^assumption.id and at.threat_id == ^threat.id
      )
    )
    |> case do
      {1, nil} -> {:ok, assumption |> Repo.preload(:threats, force: true)}
      {:error, _} -> {:error, assumption}
    end
  end

  def add_assumption_to_mitigation(%Mitigation{} = mitigation, %Assumption{} = assumption) do
    %AssumptionMitigation{assumption_id: assumption.id, mitigation_id: mitigation.id}
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, mitigation |> Repo.preload(:assumptions, force: true)}
      {:error, _} -> {:error, mitigation}
    end
  end

  def remove_assumption_from_mitigation(%Mitigation{} = mitigation, %Assumption{} = assumption) do
    Repo.delete_all(
      from(am in AssumptionMitigation,
        where: am.assumption_id == ^assumption.id and am.mitigation_id == ^mitigation.id
      )
    )
    |> case do
      {1, nil} -> {:ok, mitigation |> Repo.preload(:assumptions, force: true)}
      {:error, _} -> {:error, mitigation}
    end
  end

  def add_threat_to_mitigation(%Mitigation{} = mitigation, %Threat{} = threat) do
    %MitigationThreat{mitigation_id: mitigation.id, threat_id: threat.id}
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, mitigation |> Repo.preload(:threats, force: true)}
      {:error, _} -> {:error, mitigation}
    end
  end

  def remove_threat_from_mitigation(%Mitigation{} = mitigation, %Threat{} = threat) do
    Repo.delete_all(
      from(mt in MitigationThreat,
        where: mt.mitigation_id == ^mitigation.id and mt.threat_id == ^threat.id
      )
    )
    |> case do
      {1, nil} -> {:ok, mitigation |> Repo.preload(:threats, force: true)}
      {:error, _} -> {:error, mitigation}
    end
  end

  def add_mitigation_to_assumption(%Assumption{} = assumption, %Mitigation{} = mitigation) do
    %AssumptionMitigation{assumption_id: assumption.id, mitigation_id: mitigation.id}
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, assumption |> Repo.preload(:mitigations, force: true)}
      {:error, _} -> {:error, assumption}
    end
  end

  def remove_mitigation_from_assumption(%Assumption{} = assumption, %Mitigation{} = mitigation) do
    Repo.delete_all(
      from(am in AssumptionMitigation,
        where: am.assumption_id == ^assumption.id and am.mitigation_id == ^mitigation.id
      )
    )
    |> case do
      {1, nil} -> {:ok, assumption |> Repo.preload(:mitigations, force: true)}
      {:error, _} -> {:error, assumption}
    end
  end

  def add_assumption_to_evidence(%Evidence{} = evidence, %Assumption{} = assumption) do
    %EvidenceAssumption{evidence_id: evidence.id, assumption_id: assumption.id}
    |> Repo.insert(on_conflict: :nothing)
    |> case do
      {:ok, _} -> {:ok, evidence |> Repo.preload(:assumptions, force: true)}
      {:error, _} -> {:error, evidence}
    end
  end

  def remove_assumption_from_evidence(%Evidence{} = evidence, %Assumption{} = assumption) do
    Repo.delete_all(
      from(ea in EvidenceAssumption,
        where: ea.evidence_id == ^evidence.id and ea.assumption_id == ^assumption.id
      )
    )
    |> case do
      {_, nil} -> {:ok, evidence |> Repo.preload(:assumptions, force: true)}
      {:error, _} -> {:error, evidence}
    end
  end

  def add_threat_to_evidence(%Evidence{} = evidence, %Threat{} = threat) do
    %EvidenceThreat{evidence_id: evidence.id, threat_id: threat.id}
    |> Repo.insert(on_conflict: :nothing)
    |> case do
      {:ok, _} -> {:ok, evidence |> Repo.preload(:threats, force: true)}
      {:error, _} -> {:error, evidence}
    end
  end

  def remove_threat_from_evidence(%Evidence{} = evidence, %Threat{} = threat) do
    Repo.delete_all(
      from(et in EvidenceThreat,
        where: et.evidence_id == ^evidence.id and et.threat_id == ^threat.id
      )
    )
    |> case do
      {_, nil} -> {:ok, evidence |> Repo.preload(:threats, force: true)}
      {:error, _} -> {:error, evidence}
    end
  end

  def add_mitigation_to_evidence(%Evidence{} = evidence, %Mitigation{} = mitigation) do
    %EvidenceMitigation{evidence_id: evidence.id, mitigation_id: mitigation.id}
    |> Repo.insert(on_conflict: :nothing)
    |> case do
      {:ok, _} -> {:ok, evidence |> Repo.preload(:mitigations, force: true)}
      {:error, _} -> {:error, evidence}
    end
  end

  def remove_mitigation_from_evidence(%Evidence{} = evidence, %Mitigation{} = mitigation) do
    Repo.delete_all(
      from(em in EvidenceMitigation,
        where: em.evidence_id == ^evidence.id and em.mitigation_id == ^mitigation.id
      )
    )
    |> case do
      {_, nil} -> {:ok, evidence |> Repo.preload(:mitigations, force: true)}
      {:error, _} -> {:error, evidence}
    end
  end

  @doc """
  Returns the list of application_informations.

  ## Examples

      iex> list_application_informations()
      [%ApplicationInformation{}, ...]

  """
  def list_application_informations do
    Repo.all(ApplicationInformation)
  end

  @doc """
  Gets a single application_information.

  Raises `Ecto.NoResultsError` if the ApplicationInformation does not exist.

  ## Examples

      iex> get_application_information!(123)
      %ApplicationInformation{}

      iex> get_application_information!(456)
      ** (Ecto.NoResultsError)

  """
  def get_application_information!(id), do: Repo.get!(ApplicationInformation, id)

  @doc """
  Creates a application_information.

  ## Examples

      iex> create_application_information(%{field: value})
      {:ok, %ApplicationInformation{}}

      iex> create_application_information(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_application_information(attrs \\ %{}) do
    %ApplicationInformation{}
    |> ApplicationInformation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a application_information.

  ## Examples

      iex> update_application_information(application_information, %{field: new_value})
      {:ok, %ApplicationInformation{}}

      iex> update_application_information(application_information, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_application_information(%ApplicationInformation{} = application_information, attrs) do
    application_information
    |> ApplicationInformation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a application_information.

  ## Examples

      iex> delete_application_information(application_information)
      {:ok, %ApplicationInformation{}}

      iex> delete_application_information(application_information)
      {:error, %Ecto.Changeset{}}

  """
  def delete_application_information(%ApplicationInformation{} = application_information) do
    Repo.delete(application_information)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking application_information changes.

  ## Examples

      iex> change_application_information(application_information)
      %Ecto.Changeset{data: %ApplicationInformation{}}

  """
  def change_application_information(
        %ApplicationInformation{} = application_information,
        attrs \\ %{}
      ) do
    ApplicationInformation.changeset(application_information, attrs)
  end

  @doc """
  Returns the list of data_flow_diagrams.

  ## Examples

      iex> list_data_flow_diagrams()
      [%DataFlowDiagram{}, ...]

  """
  def list_data_flow_diagrams do
    Repo.all(DataFlowDiagram)
  end

  def get_data_flow_diagram_by_workspace_id(workspace_id) do
    Repo.get_by(DataFlowDiagram, workspace_id: workspace_id)
  end

  @doc """
  Gets a single data_flow_diagram.

  Raises `Ecto.NoResultsError` if the DataFlowDiagram does not exist.

  ## Examples

      iex> get_data_flow_diagram!(123)
      %DataFlowDiagram{}

      iex> get_data_flow_diagram!(456)
      ** (Ecto.NoResultsError)

  """
  def get_data_flow_diagram!(id), do: Repo.get!(DataFlowDiagram, id)

  @doc """
  Creates a data_flow_diagram.

  ## Examples

      iex> create_data_flow_diagram(%{field: value})
      {:ok, %DataFlowDiagram{}}

      iex> create_data_flow_diagram(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_data_flow_diagram(attrs \\ %{}) do
    %DataFlowDiagram{}
    |> DataFlowDiagram.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a data_flow_diagram.

  ## Examples

      iex> update_data_flow_diagram(data_flow_diagram, %{field: new_value})
      {:ok, %DataFlowDiagram{}}

      iex> update_data_flow_diagram(data_flow_diagram, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_data_flow_diagram(%DataFlowDiagram{} = data_flow_diagram, attrs) do
    data_flow_diagram
    |> DataFlowDiagram.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a data_flow_diagram.

  ## Examples

      iex> delete_data_flow_diagram(data_flow_diagram)
      {:ok, %DataFlowDiagram{}}

      iex> delete_data_flow_diagram(data_flow_diagram)
      {:error, %Ecto.Changeset{}}

  """
  def delete_data_flow_diagram(%DataFlowDiagram{} = data_flow_diagram) do
    Repo.delete(data_flow_diagram)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking data_flow_diagram changes.

  ## Examples

      iex> change_data_flow_diagram(data_flow_diagram)
      %Ecto.Changeset{data: %DataFlowDiagram{}}

  """
  def change_data_flow_diagram(
        %DataFlowDiagram{} = data_flow_diagram,
        attrs \\ %{}
      ) do
    DataFlowDiagram.changeset(data_flow_diagram, attrs)
  end

  @doc """
  Returns the list of architectures.

  ## Examples

      iex> list_architectures()
      [%Architecture{}, ...]

  """
  def list_architectures do
    Repo.all(Architecture)
  end

  @doc """
  Gets a single architecture.

  Raises `Ecto.NoResultsError` if the Architecture does not exist.

  ## Examples

      iex> get_architecture!(123)
      %Architecture{}

      iex> get_architecture!(456)
      ** (Ecto.NoResultsError)

  """
  def get_architecture!(id), do: Repo.get!(Architecture, id)

  @doc """
  Creates a architecture.

  ## Examples

      iex> create_architecture(%{field: value})
      {:ok, %Architecture{}}

      iex> create_architecture(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_architecture(attrs \\ %{}) do
    %Architecture{}
    |> Architecture.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a architecture.

  ## Examples

      iex> update_architecture(architecture, %{field: new_value})
      {:ok, %Architecture{}}

      iex> update_architecture(architecture, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_architecture(%Architecture{} = architecture, attrs) do
    architecture
    |> Architecture.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a architecture.

  ## Examples

      iex> delete_architecture(architecture)
      {:ok, %Architecture{}}

      iex> delete_architecture(architecture)
      {:error, %Ecto.Changeset{}}

  """
  def delete_architecture(%Architecture{} = architecture) do
    Repo.delete(architecture)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking architecture changes.

  ## Examples

      iex> change_architecture(architecture)
      %Ecto.Changeset{data: %Architecture{}}

  """
  def change_architecture(
        %Architecture{} = architecture,
        attrs \\ %{}
      ) do
    Architecture.changeset(architecture, attrs)
  end

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
        |> create_assumption()

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
        |> create_threat()

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
        |> create_mitigation()

      _ ->
        {:error, "Invalid collection type"}
    end
  end

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

  @doc """
  Returns the list of users ordered by email.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    from(u in User, order_by: u.email)
    |> Repo.all()
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(
        %User{} = user,
        attrs \\ %{}
      ) do
    User.changeset(user, attrs)
  end

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

  @doc """
  Returns the list of evidence for a workspace.

  ## Examples

      iex> list_evidence(workspace_id)
      [%Evidence{}, ...]

  """
  def list_evidence(workspace_id) do
    Repo.all(from e in Evidence, where: e.workspace_id == ^workspace_id)
  end

  @doc """
  Gets a single evidence.

  Raises `Ecto.NoResultsError` if the Evidence does not exist.

  ## Examples

      iex> get_evidence!(123)
      %Evidence{}

      iex> get_evidence!(456)
      ** (Ecto.NoResultsError)

  """
  def get_evidence!(id, _preload \\ nil)

  def get_evidence!(id, preload) when is_list(preload) do
    Repo.get!(Evidence, id)
    |> Repo.preload(preload)
  end

  def get_evidence!(id, preload) when is_nil(preload), do: Repo.get!(Evidence, id)

  @doc """
  Creates evidence.

  ## Examples

      iex> create_evidence(%{field: value})
      {:ok, %Evidence{}}

      iex> create_evidence(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_evidence(attrs \\ %{}) do
    %Evidence{}
    |> Evidence.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates evidence.

  ## Examples

      iex> update_evidence(evidence, %{field: new_value})
      {:ok, %Evidence{}}

      iex> update_evidence(evidence, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_evidence(%Evidence{} = evidence, attrs) do
    evidence
    |> Evidence.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes evidence.

  ## Examples

      iex> delete_evidence(evidence)
      {:ok, %Evidence{}}

      iex> delete_evidence(evidence)
      {:error, %Ecto.Changeset{}}

  """
  def delete_evidence(%Evidence{} = evidence) do
    Repo.delete(evidence)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking evidence changes.

  ## Examples

      iex> change_evidence(evidence)
      %Ecto.Changeset{data: %Evidence{}}

  """
  def change_evidence(%Evidence{} = evidence, attrs \\ %{}) do
    Evidence.changeset(evidence, attrs)
  end

  @doc """
  Creates evidence with automatic linking based on provided parameters.

  This function handles the creation of evidence and its automatic linking to
  assumptions, threats, and mitigations based on the provided linking strategy.

  ## Parameters
    - evidence_attrs: Evidence attributes for creation
    - linking_opts: Map containing linking options:
      - assumption_id: Direct link to assumption
      - threat_id: Direct link to threat
      - mitigation_id: Direct link to mitigation
      - use_ai: Boolean flag for AI-based linking (stubbed)

  ## Returns
    {:ok, evidence_with_associations} | {:error, changeset}

  ## Examples

      iex> create_evidence_with_linking(%{name: "Test", evidence_type: :json_data, content: %{}}, %{assumption_id: "uuid"})
      {:ok, %Evidence{}}

  """
  def create_evidence_with_linking(evidence_attrs, linking_opts \\ %{}) do
    case create_evidence(evidence_attrs) do
      {:ok, evidence} ->
        # This would be called by the API controller for centralized linking logic
        linked_evidence = apply_evidence_linking(evidence, linking_opts)

        evidence_with_associations =
          Repo.preload(linked_evidence, [:assumptions, :threats, :mitigations])

        {:ok, evidence_with_associations}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Applies linking logic to evidence based on provided options.

  ## Parameters
    - evidence: The evidence to link
    - linking_opts: Map containing linking strategy options

  ## Returns
    The evidence (linking is done via side effects to join tables)
  """
  def apply_evidence_linking(evidence, linking_opts) do
    # Direct ID linking takes precedence
    if has_direct_linking_ids?(linking_opts) do
      apply_direct_evidence_linking(evidence, linking_opts)
    else
      # NIST control-based linking when evidence has nist_controls
      apply_nist_control_evidence_linking(evidence, linking_opts)
    end
  end

  defp has_direct_linking_ids?(linking_opts) do
    Map.get(linking_opts, :assumption_id) ||
      Map.get(linking_opts, :threat_id) ||
      Map.get(linking_opts, :mitigation_id)
  end

  defp apply_direct_evidence_linking(evidence, linking_opts) do
    if assumption_id = Map.get(linking_opts, :assumption_id) do
      link_evidence_to_assumption_by_id(evidence, assumption_id)
    end

    if threat_id = Map.get(linking_opts, :threat_id) do
      link_evidence_to_threat_by_id(evidence, threat_id)
    end

    if mitigation_id = Map.get(linking_opts, :mitigation_id) do
      link_evidence_to_mitigation_by_id(evidence, mitigation_id)
    end

    evidence
  end

  defp link_evidence_to_assumption_by_id(evidence, assumption_id) do
    try do
      assumption = get_assumption!(assumption_id)

      if assumption.workspace_id == evidence.workspace_id do
        Repo.insert(
          %EvidenceAssumption{evidence_id: evidence.id, assumption_id: assumption.id},
          on_conflict: :nothing,
          conflict_target: [:evidence_id, :assumption_id]
        )
      end
    rescue
      Ecto.NoResultsError -> :ok
    end
  end

  defp link_evidence_to_threat_by_id(evidence, threat_id) do
    try do
      threat = get_threat!(threat_id)

      if threat.workspace_id == evidence.workspace_id do
        Repo.insert(
          %EvidenceThreat{evidence_id: evidence.id, threat_id: threat.id},
          on_conflict: :nothing,
          conflict_target: [:evidence_id, :threat_id]
        )
      end
    rescue
      Ecto.NoResultsError -> :ok
    end
  end

  defp apply_nist_control_evidence_linking(evidence, _linking_opts) do
    # Only proceed if evidence has NIST controls defined
    if evidence.nist_controls && length(evidence.nist_controls) > 0 do
      link_evidence_by_nist_controls(evidence)
    end

    evidence
  end

  defp link_evidence_by_nist_controls(evidence) do
    workspace_id = evidence.workspace_id
    nist_controls = evidence.nist_controls

    # Find assumptions with overlapping NIST controls in tags
    assumptions = find_assumptions_by_nist_tags(workspace_id, nist_controls)

    Enum.each(assumptions, fn assumption ->
      Repo.insert(
        %EvidenceAssumption{evidence_id: evidence.id, assumption_id: assumption.id},
        on_conflict: :nothing,
        conflict_target: [:evidence_id, :assumption_id]
      )
    end)

    # Find threats with overlapping NIST controls in tags
    threats = find_threats_by_nist_tags(workspace_id, nist_controls)

    Enum.each(threats, fn threat ->
      Repo.insert(
        %EvidenceThreat{evidence_id: evidence.id, threat_id: threat.id},
        on_conflict: :nothing,
        conflict_target: [:evidence_id, :threat_id]
      )
    end)

    # Find mitigations with overlapping NIST controls in tags
    mitigations = find_mitigations_by_nist_tags(workspace_id, nist_controls)

    Enum.each(mitigations, fn mitigation ->
      Repo.insert(
        %EvidenceMitigation{evidence_id: evidence.id, mitigation_id: mitigation.id},
        on_conflict: :nothing,
        conflict_target: [:evidence_id, :mitigation_id]
      )
    end)
  end

  defp find_assumptions_by_nist_tags(workspace_id, nist_controls) do
    from(a in Assumption,
      where: a.workspace_id == ^workspace_id and fragment("? && ?", a.tags, ^nist_controls)
    )
    |> Repo.all()
  end

  defp find_threats_by_nist_tags(workspace_id, nist_controls) do
    from(t in Threat,
      where: t.workspace_id == ^workspace_id and fragment("? && ?", t.tags, ^nist_controls)
    )
    |> Repo.all()
  end

  defp find_mitigations_by_nist_tags(workspace_id, nist_controls) do
    from(m in Mitigation,
      where: m.workspace_id == ^workspace_id and fragment("? && ?", m.tags, ^nist_controls)
    )
    |> Repo.all()
  end

  defp link_evidence_to_mitigation_by_id(evidence, mitigation_id) do
    try do
      mitigation = get_mitigation!(mitigation_id)

      if mitigation.workspace_id == evidence.workspace_id do
        Repo.insert(
          %EvidenceMitigation{evidence_id: evidence.id, mitigation_id: mitigation.id},
          on_conflict: :nothing,
          conflict_target: [:evidence_id, :mitigation_id]
        )
      end
    rescue
      Ecto.NoResultsError -> :ok
    end
  end

  # Brainstorm Items functions

  @doc """
  Returns the list of brainstorm items for a workspace.

  ## Examples

      iex> list_brainstorm_items(workspace_id)
      [%BrainstormItem{}, ...]

  """
  def list_brainstorm_items(workspace_id, filters \\ %{}) do
    workspace_id
    |> brainstorm_items_base_query()
    |> apply_brainstorm_filters(filters)
    |> order_brainstorm_by_position()
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
  Returns distinct non-nil cluster keys for a given workspace and brainstorm item type.

  ## Examples

      iex> list_clusters_by_type(workspace_id, :threat)
      ["Authentication", "Secrets", ...]

  """
  def list_clusters_by_type(workspace_id, type) when is_binary(workspace_id) do
    workspace_id
    |> brainstorm_items_base_query()
    |> where([bi], not is_nil(bi.cluster_key) and bi.type == ^type)
    |> distinct([bi], bi.cluster_key)
    |> select([bi], bi.cluster_key)
    |> order_by([bi], asc: bi.cluster_key)
    |> Repo.all()
  end

  @doc """
  Returns items in a specific cluster.

  ## Examples

      iex> list_cluster_items(workspace_id, "cluster_123")
      [%BrainstormItem{}, ...]

  """
  def list_cluster_items(workspace_id, cluster_key) do
    workspace_id
    |> brainstorm_items_base_query()
    |> where([bi], bi.cluster_key == ^cluster_key)
    |> order_brainstorm_by_position()
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
      |> brainstorm_items_base_query()
      |> where([bi], bi.status in [:clustered, :candidate])

    query = if cluster_key, do: where(query, [bi], bi.cluster_key == ^cluster_key), else: query

    query
    |> order_brainstorm_by_position()
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
    |> brainstorm_items_base_query()
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
    |> brainstorm_items_base_query()
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
        emit_brainstorm_telemetry(:created, item)
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
        emit_brainstorm_telemetry(:updated, updated_item)

        if old_status != updated_item.status do
          emit_brainstorm_telemetry(:status_changed, updated_item, %{
            old_status: old_status,
            new_status: updated_item.status
          })
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
        emit_brainstorm_telemetry(:cluster_assigned, updated_item)
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
    |> brainstorm_items_base_query()
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
    |> brainstorm_items_base_query()
    |> group_by([bi], bi.type)
    |> select([bi], {bi.type, count(bi.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  # Private functions for brainstorm items

  defp brainstorm_items_base_query(workspace_id) do
    from(bi in BrainstormItem, where: bi.workspace_id == ^workspace_id)
  end

  defp apply_brainstorm_filters(query, filters) do
    Enum.reduce(filters, query, &apply_brainstorm_filter/2)
  end

  defp apply_brainstorm_filter({:type, type}, query) when not is_nil(type) do
    where(query, [bi], bi.type == ^type)
  end

  defp apply_brainstorm_filter({:status, status}, query) when not is_nil(status) do
    where(query, [bi], bi.status == ^status)
  end

  defp apply_brainstorm_filter({:cluster_key, cluster_key}, query) when not is_nil(cluster_key) do
    where(query, [bi], bi.cluster_key == ^cluster_key)
  end

  defp apply_brainstorm_filter(_, query), do: query

  defp order_brainstorm_by_position(query) do
    order_by(query, [bi], asc: bi.position, asc: bi.inserted_at)
  end

  # Telemetry events for brainstorm items

  defp emit_brainstorm_telemetry(event, item, metadata \\ %{}) do
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
