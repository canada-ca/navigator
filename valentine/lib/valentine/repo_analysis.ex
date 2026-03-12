defmodule Valentine.RepoAnalysis do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Jido.AgentServer
  alias Jido.Signal
  alias Phoenix.PubSub
  alias Valentine.Composer
  alias Valentine.Composer.RepoAnalysisAgent
  alias Valentine.RepoAnalysis.GitHub
  alias Valentine.RepoAnalysis.Runner
  alias Valentine.Repo

  @pubsub Valentine.PubSub

  def default_limits do
    Application.get_env(:valentine, :repo_analysis, [])
    |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
  end

  def topic(owner), do: "repo_analysis_agents:owner:#{owner}"
  def job_topic(job_id), do: "repo_analysis_agents:job:#{job_id}"
  def workspace_topic(workspace_id), do: "repo_analysis_agents:workspace:#{workspace_id}"

  def create_import(owner, attrs) do
    with {:ok, github_url} <- validate_github_url(attrs) do
      workspace_attrs = workspace_attrs(owner, attrs)
      requested_at = DateTime.utc_now()

      Multi.new()
      |> Multi.insert(
        :workspace,
        Composer.change_workspace(%Valentine.Composer.Workspace{}, workspace_attrs)
      )
      |> Multi.insert(:repo_analysis_agent, fn %{workspace: workspace} ->
        Composer.change_repo_analysis_agent(%RepoAnalysisAgent{}, %{
          workspace_id: workspace.id,
          owner: owner,
          github_url: github_url,
          requested_at: requested_at,
          limits: default_limits(),
          progress_message: "Queued for repository analysis"
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{workspace: workspace, repo_analysis_agent: repo_analysis_agent}} ->
          with {:ok, repo_analysis_agent} <- launch(repo_analysis_agent) do
            {:ok, %{workspace: workspace, repo_analysis_agent: repo_analysis_agent}}
          else
            {:error, reason} ->
              _ =
                Composer.update_repo_analysis_agent(repo_analysis_agent, %{
                  status: :failed,
                  failure_reason: format_error(reason),
                  completed_at: DateTime.utc_now(),
                  progress_message: "Failed to start repository analysis"
                })

              {:error, reason}
          end

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    else
      {:error, reason} ->
        {:error, invalid_import_changeset(attrs, reason)}
    end
  end

  def launch(%RepoAnalysisAgent{} = repo_analysis_agent) do
    runtime_agent_id = runtime_agent_id(repo_analysis_agent.id)

    with {:ok, repo_analysis_agent} <-
           Composer.update_repo_analysis_agent(repo_analysis_agent, %{
             runtime_agent_id: runtime_agent_id
           }) do
      if runtime_start_enabled?() do
        {:ok, pid} =
          Valentine.Jido.start_agent(Valentine.RepoAnalysis.Agent,
            id: runtime_agent_id,
            initial_state: %{
              repo_analysis_agent_id: repo_analysis_agent.id,
              workspace_id: repo_analysis_agent.workspace_id,
              owner: repo_analysis_agent.owner,
              github_url: repo_analysis_agent.github_url
            }
          )

        :ok =
          AgentServer.cast(
            pid,
            Signal.new!("repo_analysis.start", %{}, source: "/repo_analysis")
          )
      end

      broadcast(repo_analysis_agent)
      {:ok, repo_analysis_agent}
    end
  end

  def cancel_for_owner(id, owner) do
    case Composer.get_repo_analysis_agent_for_owner(id, owner) do
      nil ->
        {:error, :not_found}

      repo_analysis_agent ->
        with {:ok, repo_analysis_agent} <-
               Composer.request_repo_analysis_agent_cancel(repo_analysis_agent) do
          case repo_analysis_agent.runtime_agent_id &&
                 Valentine.Jido.whereis(repo_analysis_agent.runtime_agent_id) do
            pid when is_pid(pid) ->
              :ok =
                AgentServer.cast(
                  pid,
                  Signal.new!("repo_analysis.cancel", %{}, source: "/repo_analysis")
                )

              broadcast(repo_analysis_agent)
              {:ok, repo_analysis_agent}

            _ ->
              {:ok, updated_repo_analysis_agent} =
                Composer.update_repo_analysis_agent(repo_analysis_agent, %{
                  status: :cancelled,
                  completed_at: DateTime.utc_now(),
                  progress_message: "Repository analysis cancelled"
                })

              broadcast(updated_repo_analysis_agent)
              {:ok, updated_repo_analysis_agent}
          end
        end
    end
  end

  def running_status?(status)
      when status in [
             :queued,
             :cloning,
             :indexing,
             :summarizing,
             :generating_dfd,
             :generating_threat_model,
             :persisting_results
           ],
      do: true

  def running_status?(_status), do: false

  def recover_stale_jobs do
    stale_jobs = list_stale_jobs()

    Enum.each(stale_jobs, &timeout_job/1)

    length(stale_jobs)
  end

  def update_status(repo_analysis_agent_id, attrs) do
    repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent_id)

    result =
      Composer.update_repo_analysis_agent(
        repo_analysis_agent,
        Map.put(attrs, :last_heartbeat_at, DateTime.utc_now())
      )

    case result do
      {:ok, updated_repo_analysis_agent} ->
        broadcast(updated_repo_analysis_agent)
        {:ok, updated_repo_analysis_agent}

      error ->
        error
    end
  end

  def mark_cancelled(repo_analysis_agent_id, message \\ "Repository analysis cancelled") do
    update_status(repo_analysis_agent_id, %{
      status: :cancelled,
      progress_message: message,
      completed_at: DateTime.utc_now()
    })
  end

  def broadcast(%RepoAnalysisAgent{} = repo_analysis_agent) do
    payload = %{event: :repo_analysis_updated, repo_analysis_agent_id: repo_analysis_agent.id}

    PubSub.broadcast(@pubsub, topic(repo_analysis_agent.owner), payload)
    PubSub.broadcast(@pubsub, job_topic(repo_analysis_agent.id), payload)
    PubSub.broadcast(@pubsub, workspace_topic(repo_analysis_agent.workspace_id), payload)
  end

  def runtime_agent_id(job_id), do: "repo-analysis-#{job_id}"

  defp runtime_start_enabled? do
    Application.get_env(:valentine, :repo_analysis, [])
    |> Keyword.get(:start_runtime, true)
  end

  defp list_stale_jobs do
    cutoff = DateTime.add(DateTime.utc_now(), -heartbeat_timeout_seconds(), :second)

    from(agent in RepoAnalysisAgent,
      where: agent.status in ^running_statuses()
    )
    |> Repo.all()
    |> Enum.filter(&stale_job?(&1, cutoff))
  end

  defp timeout_job(%RepoAnalysisAgent{} = repo_analysis_agent) do
    Runner.cleanup(repo_analysis_agent.id)
    stop_runtime(repo_analysis_agent.runtime_agent_id)

    {:ok, updated_repo_analysis_agent} =
      Composer.update_repo_analysis_agent(repo_analysis_agent, %{
        status: :timed_out,
        progress_message: "Repository analysis timed out",
        failure_reason: "No heartbeat received before the recovery timeout elapsed",
        completed_at: DateTime.utc_now()
      })

    broadcast(updated_repo_analysis_agent)
    updated_repo_analysis_agent
  end

  defp stop_runtime(runtime_agent_id) when is_binary(runtime_agent_id) do
    _ = Valentine.Jido.stop_agent(runtime_agent_id)
    :ok
  rescue
    _ -> :ok
  end

  defp stop_runtime(_runtime_agent_id), do: :ok

  defp stale_job?(repo_analysis_agent, cutoff) do
    reference_time =
      repo_analysis_agent.last_heartbeat_at ||
        repo_analysis_agent.started_at ||
        repo_analysis_agent.requested_at || repo_analysis_agent.updated_at

    DateTime.compare(reference_time, cutoff) == :lt
  end

  defp running_statuses do
    [
      :queued,
      :cloning,
      :indexing,
      :summarizing,
      :generating_dfd,
      :generating_threat_model,
      :persisting_results
    ]
  end

  defp heartbeat_timeout_seconds do
    Application.get_env(:valentine, :repo_analysis, [])
    |> Keyword.get(:heartbeat_timeout_ms, 300_000)
    |> div(1000)
  end

  defp validate_github_url(attrs) do
    github_url = Map.get(attrs, "github_url") || Map.get(attrs, :github_url) || ""

    github_url
    |> GitHub.parse_public_url()
    |> case do
      {:ok, _repo_ref} -> {:ok, github_url}
      {:error, reason} -> {:error, reason}
    end
  end

  defp invalid_import_changeset(attrs, reason) do
    {%{}, %{github_url: :string}}
    |> Changeset.cast(attrs, [:github_url])
    |> Changeset.add_error(:github_url, reason)
  end

  defp workspace_attrs(owner, attrs) do
    github_url = Map.get(attrs, "github_url") || Map.get(attrs, :github_url) || ""

    %{
      "name" =>
        Map.get(attrs, "name") || Map.get(attrs, :name) || infer_workspace_name(github_url),
      "cloud_profile" => Map.get(attrs, "cloud_profile") || Map.get(attrs, :cloud_profile),
      "cloud_profile_type" =>
        Map.get(attrs, "cloud_profile_type") || Map.get(attrs, :cloud_profile_type),
      "url" => github_url,
      "owner" => owner
    }
  end

  defp infer_workspace_name(github_url) do
    github_url
    |> URI.parse()
    |> Map.get(:path, "")
    |> String.trim("/")
    |> String.split("/")
    |> List.last()
    |> case do
      nil -> "GitHub Import"
      "" -> "GitHub Import"
      name -> String.replace_suffix(name, ".git", "")
    end
  end

  defp format_error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field} #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)
end
