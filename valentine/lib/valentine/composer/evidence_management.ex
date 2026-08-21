defmodule Valentine.Composer.EvidenceManagement do
  @moduledoc """
  Evidence persistence, linking, and association orchestration.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Assumption
  alias Valentine.Composer.Assumptions
  alias Valentine.Composer.Evidence
  alias Valentine.Composer.EvidenceAssumption
  alias Valentine.Composer.EvidenceMitigation
  alias Valentine.Composer.EvidenceThreat
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.Mitigations
  alias Valentine.Composer.QueryHelpers
  alias Valentine.Composer.Threat
  alias Valentine.Composer.Threats

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

  def get_evidence_for_workspace!(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity!(Evidence, workspace_id, id, preload)
  end

  def get_evidence_for_workspace(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity(Evidence, workspace_id, id, preload)
  end

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
      assumption = Assumptions.get_assumption!(assumption_id)

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
      threat = Threats.get_threat!(threat_id)

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
      mitigation = Mitigations.get_mitigation!(mitigation_id)

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
end
