defmodule Valentine.Composer.Relationships do
  @moduledoc """
  Cross-capability associations for threat-model entities and evidence.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Assumption
  alias Valentine.Composer.AssumptionMitigation
  alias Valentine.Composer.AssumptionThreat
  alias Valentine.Composer.Evidence
  alias Valentine.Composer.EvidenceAssumption
  alias Valentine.Composer.EvidenceMitigation
  alias Valentine.Composer.EvidenceThreat
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.MitigationThreat
  alias Valentine.Composer.Threat

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
      {_n, nil} -> {:ok, threat |> Repo.preload(:assumptions, force: true)}
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
      {_n, nil} -> {:ok, threat |> Repo.preload(:mitigations, force: true)}
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
      {_n, nil} -> {:ok, assumption |> Repo.preload(:threats, force: true)}
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
      {_n, nil} -> {:ok, mitigation |> Repo.preload(:assumptions, force: true)}
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
      {_n, nil} -> {:ok, mitigation |> Repo.preload(:threats, force: true)}
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
      {_n, nil} -> {:ok, assumption |> Repo.preload(:mitigations, force: true)}
    end
  end

  def add_assumption_to_evidence(%Evidence{} = evidence, %Assumption{} = assumption) do
    %EvidenceAssumption{evidence_id: evidence.id, assumption_id: assumption.id}
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:evidence_id, :assumption_id])
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

    {:ok, evidence |> Repo.preload(:assumptions, force: true)}
  end

  def add_threat_to_evidence(%Evidence{} = evidence, %Threat{} = threat) do
    %EvidenceThreat{evidence_id: evidence.id, threat_id: threat.id}
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:evidence_id, :threat_id])
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

    {:ok, evidence |> Repo.preload(:threats, force: true)}
  end

  def add_mitigation_to_evidence(%Evidence{} = evidence, %Mitigation{} = mitigation) do
    %EvidenceMitigation{evidence_id: evidence.id, mitigation_id: mitigation.id}
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:evidence_id, :mitigation_id])
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

    {:ok, evidence |> Repo.preload(:mitigations, force: true)}
  end
end
