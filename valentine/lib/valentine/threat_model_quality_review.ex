defmodule Valentine.ThreatModelQualityReview do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Jido.AgentServer
  alias Jido.Signal
  alias Phoenix.PubSub
  alias Valentine.Composer
  alias Valentine.Composer.ThreatModelQualityReviewRun
  alias Valentine.Composer.Workspace
  alias Valentine.Repo

  @pubsub Valentine.PubSub

  def topic(owner), do: "threat_model_quality_reviews:owner:#{owner}"
  def job_topic(job_id), do: "threat_model_quality_reviews:job:#{job_id}"
  def workspace_topic(workspace_id), do: "threat_model_quality_reviews:workspace:#{workspace_id}"

  def start_review(workspace_id, identity) do
    workspace = Composer.get_workspace!(workspace_id)

    with :ok <- ensure_workspace_access(workspace, identity),
         :ok <- ensure_no_running_review(workspace.id),
         {:ok, run} <-
           Composer.create_threat_model_quality_review_run(%{
             workspace_id: workspace.id,
             owner: identity,
             requested_at: DateTime.utc_now(),
             progress_message: "Queued for threat model quality review"
           }) do
      launch_created_run(run)
    end
  end

  def launch(%ThreatModelQualityReviewRun{} = run) do
    runtime_agent_id = runtime_agent_id(run.id)

    with {:ok, run} <-
           Composer.update_threat_model_quality_review_run(run, %{
             runtime_agent_id: runtime_agent_id
           }) do
      result =
        if runtime_start_enabled?() do
          case Valentine.Jido.start_agent(Valentine.ThreatModelQualityReview.Agent,
                 id: runtime_agent_id,
                 initial_state: %{
                   run_id: run.id,
                   workspace_id: run.workspace_id,
                   owner: run.owner
                 }
               ) do
            {:ok, pid} ->
              :ok =
                AgentServer.cast(
                  pid,
                  Signal.new!("quality_review.start", %{}, source: "/quality_review")
                )

              {:ok, run}

            {:error, {:already_started, pid}} ->
              :ok =
                AgentServer.cast(
                  pid,
                  Signal.new!("quality_review.start", %{}, source: "/quality_review")
                )

              {:ok, run}

            {:error, reason} ->
              {:error, reason}
          end
        else
          {:ok, run}
        end

      case result do
        {:ok, updated_run} ->
          broadcast(updated_run)
          {:ok, updated_run}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def cancel_for_owner(id, owner) do
    case Composer.get_threat_model_quality_review_run_for_owner(id, owner) do
      nil ->
        {:error, :not_found}

      run ->
        with {:ok, run} <- Composer.request_threat_model_quality_review_run_cancel(run) do
          case run.runtime_agent_id && Valentine.Jido.whereis(run.runtime_agent_id) do
            pid when is_pid(pid) ->
              :ok =
                AgentServer.cast(
                  pid,
                  Signal.new!("quality_review.cancel", %{}, source: "/quality_review")
                )

              broadcast(run)
              {:ok, run}

            _ ->
              {:ok, updated_run} =
                Composer.update_threat_model_quality_review_run(run, %{
                  status: :cancelled,
                  completed_at: DateTime.utc_now(),
                  progress_message: "Threat model quality review cancelled"
                })

              broadcast(updated_run)
              {:ok, updated_run}
          end
        end
    end
  end

  def retry_for_owner(id, owner) do
    case Composer.get_threat_model_quality_review_run_for_owner(id, owner) do
      nil ->
        {:error, :not_found}

      %ThreatModelQualityReviewRun{workspace: %Workspace{} = workspace} = run ->
        if rerunnable_status?(run.status) do
          start_review(workspace.id, owner)
        else
          {:error, :not_retryable}
        end

      _ ->
        {:error, :not_found}
    end
  end

  def delete_for_owner(id, owner) do
    case Composer.get_threat_model_quality_review_run_for_owner(id, owner) do
      nil ->
        {:error, :not_found}

      run ->
        stop_runtime(run.runtime_agent_id)

        case Composer.delete_threat_model_quality_review_run(run) do
          {:ok, deleted_run} ->
            broadcast(deleted_run)
            {:ok, deleted_run}

          error ->
            error
        end
    end
  end

  def running_status?(status)
      when status in [:queued, :assembling_context, :reviewing, :persisting_results],
      do: true

  def running_status?(_status), do: false

  def rerunnable_status?(status) when status in [:completed, :failed, :cancelled, :timed_out],
    do: true

  def rerunnable_status?(_status), do: false

  def recover_stale_runs do
    stale_runs = list_stale_runs()

    Enum.each(stale_runs, &timeout_run/1)

    length(stale_runs)
  end

  def update_status(run_id, attrs) do
    run = Composer.get_threat_model_quality_review_run!(run_id)

    result =
      Composer.update_threat_model_quality_review_run(
        run,
        Map.put(attrs, :last_heartbeat_at, DateTime.utc_now())
      )

    case result do
      {:ok, updated_run} ->
        broadcast(updated_run)
        {:ok, updated_run}

      error ->
        error
    end
  end

  def mark_cancelled(run_id, message \\ "Threat model quality review cancelled") do
    update_status(run_id, %{
      status: :cancelled,
      progress_message: message,
      completed_at: DateTime.utc_now()
    })
  end

  def broadcast(%ThreatModelQualityReviewRun{} = run) do
    payload = %{event: :threat_model_quality_review_updated, run_id: run.id}

    PubSub.broadcast(@pubsub, topic(run.owner), payload)
    PubSub.broadcast(@pubsub, job_topic(run.id), payload)
    PubSub.broadcast(@pubsub, workspace_topic(run.workspace_id), payload)
  end

  def runtime_agent_id(job_id), do: "threat-model-quality-review-#{job_id}"

  defp ensure_workspace_access(%Workspace{} = workspace, identity) do
    case Workspace.check_workspace_permissions(workspace, identity) do
      nil -> {:error, :not_found}
      _permission -> :ok
    end
  end

  defp ensure_no_running_review(workspace_id) do
    if Enum.any?(
         Composer.list_threat_model_quality_review_runs_by_workspace(workspace_id),
         &running_status?(&1.status)
       ) do
      {:error, :already_running}
    else
      :ok
    end
  end

  defp launch_created_run(run) do
    with {:ok, run} <- launch(run) do
      {:ok, run}
    else
      {:error, reason} ->
        _ =
          Composer.update_threat_model_quality_review_run(run, %{
            status: :failed,
            failure_reason: format_error(reason),
            completed_at: DateTime.utc_now(),
            progress_message: "Failed to start threat model quality review"
          })

        {:error, reason}
    end
  end

  defp runtime_start_enabled? do
    Application.get_env(:valentine, :threat_model_quality_review, [])
    |> Keyword.get(:start_runtime, true)
  end

  defp list_stale_runs do
    cutoff = DateTime.add(DateTime.utc_now(), -heartbeat_timeout_seconds(), :second)

    from(run in ThreatModelQualityReviewRun,
      where: run.status in ^running_statuses()
    )
    |> Repo.all()
    |> Enum.filter(&stale_run?(&1, cutoff))
  end

  defp timeout_run(%ThreatModelQualityReviewRun{} = run) do
    stop_runtime(run.runtime_agent_id)

    {:ok, updated_run} =
      Composer.update_threat_model_quality_review_run(run, %{
        status: :timed_out,
        progress_message: "Threat model quality review timed out",
        failure_reason: "No heartbeat received before the recovery timeout elapsed",
        completed_at: DateTime.utc_now()
      })

    broadcast(updated_run)
    updated_run
  end

  defp stop_runtime(runtime_agent_id) when is_binary(runtime_agent_id) do
    _ = Valentine.Jido.stop_agent(runtime_agent_id)
    :ok
  rescue
    _ -> :ok
  end

  defp stop_runtime(_runtime_agent_id), do: :ok

  defp stale_run?(run, cutoff) do
    reference_time =
      run.last_heartbeat_at ||
        run.started_at ||
        run.requested_at || run.updated_at

    DateTime.compare(reference_time, cutoff) == :lt
  end

  defp running_statuses, do: [:queued, :assembling_context, :reviewing, :persisting_results]

  defp heartbeat_timeout_seconds do
    Application.get_env(:valentine, :threat_model_quality_review, [])
    |> Keyword.get(:heartbeat_timeout_ms, 300_000)
    |> div(1000)
  end

  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)
end
