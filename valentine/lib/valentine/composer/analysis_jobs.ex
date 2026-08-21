defmodule Valentine.Composer.AnalysisJobs do
  @moduledoc """
  Repository analysis agents and threat-model quality review jobs.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.RepoAnalysisAgent
  alias Valentine.Composer.ThreatModelQualityReviewFinding
  alias Valentine.Composer.ThreatModelQualityReviewRun
  alias Valentine.Composer.QueryHelpers

  @doc """
  Returns the list of repo analysis agents for a specific owner.
  """
  def list_repo_analysis_agents_by_owner(owner) do
    from(agent in RepoAnalysisAgent,
      where: agent.owner == ^owner,
      preload: [:workspace],
      order_by: [desc: agent.requested_at, desc: agent.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of repo analysis agents for a specific workspace.
  """
  def list_repo_analysis_agents_by_workspace(workspace_id) do
    from(agent in RepoAnalysisAgent,
      where: agent.workspace_id == ^workspace_id,
      order_by: [desc: agent.requested_at, desc: agent.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single repo analysis agent.
  """
  def get_repo_analysis_agent!(id, preload \\ [:workspace]) do
    Repo.get!(RepoAnalysisAgent, id)
    |> Repo.preload(preload)
  end

  @doc """
  Gets a single repo analysis agent for an owner.
  """
  def get_repo_analysis_agent_for_owner(id, owner, preload \\ [:workspace]) do
    from(agent in RepoAnalysisAgent,
      where: agent.id == ^id and agent.owner == ^owner,
      preload: ^preload
    )
    |> Repo.one()
  end

  @doc """
  Creates a repo analysis agent record.
  """
  def create_repo_analysis_agent(attrs \\ %{}) do
    %RepoAnalysisAgent{}
    |> RepoAnalysisAgent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a repo analysis agent record.
  """
  def update_repo_analysis_agent(%RepoAnalysisAgent{} = repo_analysis_agent, attrs) do
    repo_analysis_agent
    |> RepoAnalysisAgent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks a repo analysis agent as cancellation requested.
  """
  def request_repo_analysis_agent_cancel(%RepoAnalysisAgent{} = repo_analysis_agent) do
    update_repo_analysis_agent(repo_analysis_agent, %{cancel_requested_at: DateTime.utc_now()})
  end

  @doc """
  Returns an Ecto changeset for repo analysis agent changes.
  """
  def change_repo_analysis_agent(%RepoAnalysisAgent{} = repo_analysis_agent, attrs \\ %{}) do
    RepoAnalysisAgent.changeset(repo_analysis_agent, attrs)
  end

  @doc """
  Returns the list of threat model quality review runs for a specific workspace.
  """
  def list_threat_model_quality_review_runs_by_workspace(workspace_id) do
    from(run in ThreatModelQualityReviewRun,
      where: run.workspace_id == ^workspace_id,
      order_by: [desc: run.requested_at, desc: run.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of threat model quality review runs for a specific owner.
  """
  def list_threat_model_quality_review_runs_by_owner(owner) do
    from(run in ThreatModelQualityReviewRun,
      where: run.owner == ^owner,
      preload: [:workspace],
      order_by: [desc: run.requested_at, desc: run.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single threat model quality review run.
  """
  def get_threat_model_quality_review_run!(id, preload \\ [:workspace, :findings]) do
    Repo.get!(ThreatModelQualityReviewRun, id)
    |> Repo.preload(preload)
  end

  def get_threat_model_quality_review_run_for_workspace!(
        workspace_id,
        id,
        preload \\ [:workspace, :findings]
      ) do
    QueryHelpers.get_workspace_entity!(ThreatModelQualityReviewRun, workspace_id, id, preload)
  end

  @doc """
  Gets a single threat model quality review run for an owner.
  """
  def get_threat_model_quality_review_run_for_owner(id, owner, preload \\ [:workspace, :findings]) do
    from(run in ThreatModelQualityReviewRun,
      where: run.id == ^id and run.owner == ^owner,
      preload: ^preload
    )
    |> Repo.one()
  end

  @doc """
  Creates a threat model quality review run record.
  """
  def create_threat_model_quality_review_run(attrs \\ %{}) do
    %ThreatModelQualityReviewRun{}
    |> ThreatModelQualityReviewRun.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a threat model quality review run record.
  """
  def update_threat_model_quality_review_run(%ThreatModelQualityReviewRun{} = run, attrs) do
    run
    |> ThreatModelQualityReviewRun.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks a threat model quality review run as cancellation requested.
  """
  def request_threat_model_quality_review_run_cancel(%ThreatModelQualityReviewRun{} = run) do
    update_threat_model_quality_review_run(run, %{cancel_requested_at: DateTime.utc_now()})
  end

  @doc """
  Returns an Ecto changeset for threat model quality review run changes.
  """
  def change_threat_model_quality_review_run(%ThreatModelQualityReviewRun{} = run, attrs \\ %{}) do
    ThreatModelQualityReviewRun.changeset(run, attrs)
  end

  @doc """
  Deletes a threat model quality review run record.
  """
  def delete_threat_model_quality_review_run(%ThreatModelQualityReviewRun{} = run) do
    Repo.delete(run)
  end

  @doc """
  Returns the list of findings for a threat model quality review run.
  """
  def list_threat_model_quality_review_findings_by_run(run_id) do
    from(finding in ThreatModelQualityReviewFinding,
      where: finding.run_id == ^run_id,
      order_by: [asc: finding.display_order, asc: finding.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Creates a threat model quality review finding record.
  """
  def create_threat_model_quality_review_finding(attrs \\ %{}) do
    %ThreatModelQualityReviewFinding{}
    |> ThreatModelQualityReviewFinding.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an Ecto changeset for threat model quality review finding changes.
  """
  def change_threat_model_quality_review_finding(
        %ThreatModelQualityReviewFinding{} = finding,
        attrs \\ %{}
      ) do
    ThreatModelQualityReviewFinding.changeset(finding, attrs)
  end

  @doc """
  Deletes all findings for a threat model quality review run.
  """
  def delete_threat_model_quality_review_findings_for_run(run_id) do
    from(finding in ThreatModelQualityReviewFinding, where: finding.run_id == ^run_id)
    |> Repo.delete_all()
  end
end
