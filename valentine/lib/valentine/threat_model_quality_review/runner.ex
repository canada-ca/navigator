defmodule Valentine.ThreatModelQualityReview.Runner do
  @moduledoc false

  require Logger

  alias Valentine.AIProvider
  alias Valentine.Composer
  alias Valentine.ThreatModelQualityReview
  alias Valentine.ThreatModelQualityReview.Generator
  alias Valentine.ThreatModelQualityReview.Persister
  alias Valentine.ThreatModelQualityReview.Snapshot

  def run(run_id) do
    put_debug_context(:run_id, run_id)

    try do
      do_run(run_id)
    rescue
      exception ->
        Logger.error(failure_log(run_id, exception, __STACKTRACE__))

        _ =
          ThreatModelQualityReview.update_status(run_id, %{
            status: :failed,
            progress_message: "Threat model quality review failed",
            failure_reason: Exception.message(exception),
            completed_at: DateTime.utc_now()
          })

        :error
    catch
      {:threat_model_quality_review_cancelled, ^run_id} ->
        :ok
    after
      stop_runtime(run_id)
    end
  end

  def cancel(run_id) do
    ThreatModelQualityReview.mark_cancelled(run_id)
  end

  defp do_run(run_id) do
    run = Composer.get_threat_model_quality_review_run!(run_id)
    put_debug_context(:workspace_id, run.workspace_id)
    set_stage(:loading_run)
    ensure_not_cancelled!(run)

    set_stage(:assembling_context)

    ThreatModelQualityReview.update_status(run_id, %{
      status: :assembling_context,
      progress_percent: 10,
      progress_message: "Assembling workspace context",
      started_at: run.started_at || DateTime.utc_now()
    })

    snapshot = Snapshot.build(run.workspace_id)
    snapshot_counts = snapshot_counts(snapshot)

    Logger.debug(
      "[ThreatModelQualityReview] snapshot assembled run_id=#{run_id} workspace_id=#{run.workspace_id} counts=#{inspect(snapshot_counts)}"
    )

    put_debug_context(:snapshot_counts, snapshot_counts)

    ensure_not_cancelled!(Composer.get_threat_model_quality_review_run!(run_id))

    set_stage(:reviewing)

    ThreatModelQualityReview.update_status(run_id, %{
      status: :reviewing,
      progress_percent: 45,
      progress_message: "Reviewing threat model quality",
      metadata: %{
        "snapshot_counts" => snapshot_counts
      }
    })

    model_spec = AIProvider.model_spec("ThreatModelQualityReview")
    request_opts = AIProvider.request_opts("ThreatModelQualityReview", temperature: 0.0)

    put_debug_context(:model_spec, model_spec)
    put_debug_context(:request_opts, redact_request_opts(request_opts))

    Logger.debug(
      "[ThreatModelQualityReview] starting segmented review run_id=#{run_id} model_spec=#{model_spec} request_opts=#{inspect(redact_request_opts(request_opts))}"
    )

    review =
      Generator.review(
        snapshot,
        model_spec,
        request_opts
      )

    Logger.debug(
      "[ThreatModelQualityReview] review generated run_id=#{run_id} findings=#{length(review.findings)}"
    )

    set_stage(:persisting_results)

    ThreatModelQualityReview.update_status(run_id, %{
      status: :persisting_results,
      progress_percent: 80,
      progress_message: "Persisting review findings"
    })

    :ok = Persister.persist(run_id, review.findings)

    Logger.debug(
      "[ThreatModelQualityReview] findings persisted run_id=#{run_id} findings=#{length(review.findings)}"
    )

    set_stage(:completed)

    ThreatModelQualityReview.update_status(run_id, %{
      status: :completed,
      progress_percent: 100,
      progress_message: completion_message(review.findings),
      completed_at: DateTime.utc_now(),
      result_summary: build_summary(review.findings)
    })

    :ok
  end

  defp ensure_not_cancelled!(run) do
    if run.cancel_requested_at do
      ThreatModelQualityReview.mark_cancelled(run.id)
      throw({:threat_model_quality_review_cancelled, run.id})
    end
  end

  defp stop_runtime(run_id) do
    run = Composer.get_threat_model_quality_review_run!(run_id)

    if is_binary(run.runtime_agent_id) do
      _ = Valentine.Jido.stop_agent(run.runtime_agent_id)
    end
  rescue
    _ -> :ok
  end

  defp build_summary(findings) do
    %{
      finding_count: length(findings),
      high_severity_count: Enum.count(findings, &(&1.severity == :high)),
      medium_severity_count: Enum.count(findings, &(&1.severity == :medium)),
      low_severity_count: Enum.count(findings, &(&1.severity == :low)),
      info_severity_count: Enum.count(findings, &(&1.severity == :info))
    }
  end

  defp completion_message([]),
    do: "Threat model quality review completed with no actionable findings"

  defp completion_message(findings) do
    "Threat model quality review completed with #{length(findings)} findings"
  end

  defp failure_log(run_id, exception, stacktrace) do
    run = safe_get_run(run_id)
    stage = Process.get(:threat_model_quality_review_stage, :unknown)
    snapshot_counts = Process.get(:threat_model_quality_review_snapshot_counts)
    model_spec = Process.get(:threat_model_quality_review_model_spec)
    request_opts = Process.get(:threat_model_quality_review_request_opts)

    """
    [ThreatModelQualityReview] job failed
    run_id=#{run_id}
    workspace_id=#{run && run.workspace_id}
    stage=#{stage}
    persisted_status=#{run && run.status}
    persisted_progress=#{run && run.progress_percent}
    persisted_message=#{inspect(run && run.progress_message)}
    snapshot_counts=#{inspect(snapshot_counts)}
    model_spec=#{inspect(model_spec)}
    request_opts=#{inspect(request_opts)}
    #{Exception.format(:error, exception, stacktrace)}
    """
    |> String.trim()
  end

  defp safe_get_run(run_id) do
    Composer.get_threat_model_quality_review_run!(run_id)
  rescue
    _ -> nil
  end

  defp snapshot_counts(snapshot) do
    %{
      "threats" => length(snapshot.threats),
      "assumptions" => length(snapshot.assumptions),
      "mitigations" => length(snapshot.mitigations),
      "evidence" => length(snapshot.evidence),
      "dfd_nodes" => length(snapshot.dfd.nodes),
      "dfd_edges" => length(snapshot.dfd.edges)
    }
  end

  defp redact_request_opts(opts) do
    Keyword.new(opts, fn
      {key, _value} when key in [:api_key] -> {key, "[REDACTED]"}
      {key, value} -> {key, value}
    end)
  end

  defp set_stage(stage) do
    Process.put(:threat_model_quality_review_stage, stage)
  end

  defp put_debug_context(key, value) do
    Process.put(:"threat_model_quality_review_#{key}", value)
  end
end
