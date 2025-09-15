defmodule ValentineWeb.Api.EvidenceController do
  use ValentineWeb, :controller

  alias Valentine.Composer
  alias Valentine.Repo

  def create(conn, %{"evidence" => evidence_params} = params) do
    api_key = conn.assigns[:api_key]
    workspace_id = api_key.workspace_id

    # Extract linking parameters
    assumption_id = get_in(params, ["linking", "assumption_id"])
    threat_id = get_in(params, ["linking", "threat_id"])
    mitigation_id = get_in(params, ["linking", "mitigation_id"])
    use_ai = get_in(params, ["linking", "use_ai"], false)

    # Add workspace_id to evidence params
    evidence_attrs = Map.put(evidence_params, "workspace_id", workspace_id)

    case Composer.create_evidence(evidence_attrs) do
      {:ok, evidence} ->
        # Handle linking based on direct IDs
        linked_evidence = link_evidence_directly(evidence, assumption_id, threat_id, mitigation_id)

        # Handle NIST control-based linking if no direct links were made
        # Note: This is stubbed since entities don't have NIST control fields in current schema
        final_evidence = 
          if has_direct_links?(assumption_id, threat_id, mitigation_id) do
            linked_evidence
          else
            link_evidence_by_nist_controls(linked_evidence, use_ai)
          end

        # Preload associations for response
        evidence_with_associations = 
          Repo.preload(final_evidence, [:assumptions, :threats, :mitigations])

        conn
        |> put_status(:created)
        |> json(%{
          evidence: evidence_with_associations,
          message: "Evidence created successfully"
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  defp has_direct_links?(assumption_id, threat_id, mitigation_id) do
    not is_nil(assumption_id) or not is_nil(threat_id) or not is_nil(mitigation_id)
  end

  defp link_evidence_directly(evidence, assumption_id, threat_id, mitigation_id) do
    # Link to assumption if provided
    if assumption_id do
      link_evidence_to_assumption(evidence, assumption_id)
    end

    # Link to threat if provided
    if threat_id do
      link_evidence_to_threat(evidence, threat_id)
    end

    # Link to mitigation if provided
    if mitigation_id do
      link_evidence_to_mitigation(evidence, mitigation_id)
    end

    evidence
  end

  defp link_evidence_to_assumption(evidence, assumption_id) do
    try do
      assumption = Composer.get_assumption!(assumption_id)
      
      # Verify assumption belongs to same workspace
      if assumption.workspace_id == evidence.workspace_id do
        %Valentine.Composer.EvidenceAssumption{
          evidence_id: evidence.id,
          assumption_id: assumption.id
        }
        |> Repo.insert()
      end
    rescue
      Ecto.NoResultsError -> 
        # Assumption not found, skip linking
        :ok
    end
  end

  defp link_evidence_to_threat(evidence, threat_id) do
    try do
      threat = Composer.get_threat!(threat_id)
      
      # Verify threat belongs to same workspace
      if threat.workspace_id == evidence.workspace_id do
        %Valentine.Composer.EvidenceThreat{
          evidence_id: evidence.id,
          threat_id: threat.id
        }
        |> Repo.insert()
      end
    rescue
      Ecto.NoResultsError -> 
        # Threat not found, skip linking
        :ok
    end
  end

  defp link_evidence_to_mitigation(evidence, mitigation_id) do
    try do
      mitigation = Composer.get_mitigation!(mitigation_id)
      
      # Verify mitigation belongs to same workspace
      if mitigation.workspace_id == evidence.workspace_id do
        %Valentine.Composer.EvidenceMitigation{
          evidence_id: evidence.id,
          mitigation_id: mitigation.id
        }
        |> Repo.insert()
      end
    rescue
      Ecto.NoResultsError -> 
        # Mitigation not found, skip linking
        :ok
    end
  end

  defp link_evidence_by_nist_controls(evidence, use_ai) do
    # STUB: NIST control-based linking
    # Current schema shows that assumptions, threats, and mitigations 
    # do not have NIST control fields, so this feature is stubbed
    
    if use_ai do
      # STUB: AI-based linking would go here
      # This is explicitly out of scope per requirements
      evidence
    else
      # STUB: Would match entities with overlapping NIST controls
      # Since entities don't have NIST fields, this is stubbed
      evidence
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end