defmodule Valentine.RepoAnalysis.Runner do
  @moduledoc false

  require Logger

  alias Valentine.AIProvider
  alias Valentine.Composer
  alias Valentine.RepoAnalysis
  alias Valentine.RepoAnalysis.GitHub
  alias Valentine.RepoAnalysis.Generator
  alias Valentine.RepoAnalysis.Persister

  def run(repo_analysis_agent_id) do
    try do
      do_run(repo_analysis_agent_id)
    rescue
      exception ->
        Logger.error("[RepoAnalysis] job failed",
          error: inspect(exception),
          stacktrace: __STACKTRACE__
        )

        _ =
          RepoAnalysis.update_status(repo_analysis_agent_id, %{
            status: :failed,
            progress_message: "Repository analysis failed",
            failure_reason: Exception.message(exception),
            completed_at: DateTime.utc_now()
          })

        :error
    catch
      {:repo_analysis_cancelled, ^repo_analysis_agent_id} ->
        :ok
    after
      cleanup(repo_analysis_agent_id)
      stop_runtime(repo_analysis_agent_id)
    end
  end

  def cancel(repo_analysis_agent_id) do
    cleanup(repo_analysis_agent_id)
    RepoAnalysis.mark_cancelled(repo_analysis_agent_id)
  end

  def cleanup(repo_analysis_agent_id) do
    repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent_id)

    case get_in(repo_analysis_agent.metadata, ["clone_dir"]) do
      clone_dir when is_binary(clone_dir) -> File.rm_rf(clone_dir)
      _ -> :ok
    end
  end

  defp do_run(repo_analysis_agent_id) do
    repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent_id)
    ensure_not_cancelled!(repo_analysis_agent)

    RepoAnalysis.update_status(repo_analysis_agent_id, %{
      status: :cloning,
      progress_percent: 5,
      progress_message: "Cloning public GitHub repository",
      started_at: repo_analysis_agent.started_at || DateTime.utc_now()
    })

    limits = repo_analysis_agent.limits
    repo_ref = GitHub.parse_public_url!(repo_analysis_agent.github_url)
    {:ok, clone_dir, clone_metadata} = GitHub.clone(repo_ref, repo_analysis_agent_id, limits)

    RepoAnalysis.update_status(repo_analysis_agent_id, %{
      metadata: Map.merge(repo_analysis_agent.metadata, clone_metadata)
    })

    ensure_not_cancelled!(Composer.get_repo_analysis_agent!(repo_analysis_agent_id))

    RepoAnalysis.update_status(repo_analysis_agent_id, %{
      status: :indexing,
      progress_percent: 20,
      progress_message: "Indexing repository documentation and code"
    })

    {:ok, snapshot} = GitHub.build_snapshot(clone_dir, repo_ref, limits)

    RepoAnalysis.update_status(repo_analysis_agent_id, %{
      repo_full_name: repo_ref.full_name,
      repo_default_branch: snapshot.default_branch,
      metadata:
        Map.merge(
          Composer.get_repo_analysis_agent!(repo_analysis_agent_id).metadata,
          snapshot.metadata
        ),
      progress_percent: 40,
      progress_message: "Generating architecture and threat model"
    })

    ensure_not_cancelled!(Composer.get_repo_analysis_agent!(repo_analysis_agent_id))

    RepoAnalysis.update_status(repo_analysis_agent_id, %{
      status: :summarizing,
      progress_percent: 50,
      progress_message: "Summarizing repository context"
    })

    analysis =
      Generator.generate(
        snapshot,
        repo_analysis_agent.github_url,
        AIProvider.model_spec("RepoAnalysis"),
        AIProvider.request_opts("RepoAnalysis")
      )

    RepoAnalysis.update_status(repo_analysis_agent_id, %{
      status: :persisting_results,
      progress_percent: 85,
      progress_message: "Persisting generated threat model artifacts"
    })

    :ok = Persister.persist(repo_analysis_agent.workspace_id, analysis)

    RepoAnalysis.update_status(repo_analysis_agent_id, %{
      status: :completed,
      progress_percent: 100,
      progress_message: "Threat model created from GitHub repository",
      completed_at: DateTime.utc_now(),
      result_summary: %{
        threat_count: length(analysis.threats),
        assumption_count: length(analysis.assumptions),
        mitigation_count: length(analysis.mitigations),
        component_count: length(Map.get(analysis.dfd, "components", [])),
        flow_count: length(Map.get(analysis.dfd, "flows", []))
      }
    })

    :ok
  end

  defp ensure_not_cancelled!(repo_analysis_agent) do
    if repo_analysis_agent.cancel_requested_at do
      RepoAnalysis.mark_cancelled(repo_analysis_agent.id)
      throw({:repo_analysis_cancelled, repo_analysis_agent.id})
    end
  end

  defp stop_runtime(repo_analysis_agent_id) do
    repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent_id)

    if is_binary(repo_analysis_agent.runtime_agent_id) do
      _ = Valentine.Jido.stop_agent(repo_analysis_agent.runtime_agent_id)
    end
  rescue
    _ -> :ok
  end
end
