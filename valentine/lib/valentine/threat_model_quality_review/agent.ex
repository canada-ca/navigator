defmodule Valentine.ThreatModelQualityReview.Agent do
  @moduledoc false

  use Jido.Agent,
    name: "threat_model_quality_review_agent",
    description: "Runs workspace threat model quality review jobs",
    schema: [
      status: [type: :atom, default: :queued],
      run_id: [type: :string],
      workspace_id: [type: :string],
      owner: [type: :string],
      worker_pid: [type: :any, default: nil]
    ],
    signal_routes: [
      {"quality_review.start", Valentine.ThreatModelQualityReview.Agent.Start},
      {"quality_review.cancel", Valentine.ThreatModelQualityReview.Agent.Cancel}
    ]

  defmodule Start do
    @moduledoc false

    use Jido.Action,
      name: "threat_model_quality_review_agent_start",
      description: "Start the supervised threat model quality review worker",
      schema: []

    def run(_params, context) do
      case get_in(context, [:state, :worker_pid]) do
        pid when is_pid(pid) ->
          if Process.alive?(pid) do
            {:ok, %{}}
          else
            start_worker(context)
          end

        _ ->
          start_worker(context)
      end
    end

    defp start_worker(context) do
      {:ok, pid} =
        Task.Supervisor.start_child(Valentine.TaskSupervisor, fn ->
          Valentine.ThreatModelQualityReview.Runner.run(get_in(context, [:state, :run_id]))
        end)

      {:ok, %{status: :running, worker_pid: pid}}
    end
  end

  defmodule Cancel do
    @moduledoc false

    use Jido.Action,
      name: "threat_model_quality_review_agent_cancel",
      description: "Cancel the supervised threat model quality review worker",
      schema: []

    def run(_params, context) do
      worker_pid = get_in(context, [:state, :worker_pid])

      if is_pid(worker_pid) and Process.alive?(worker_pid) do
        Process.exit(worker_pid, :kill)
      end

      _ = Valentine.ThreatModelQualityReview.Runner.cancel(get_in(context, [:state, :run_id]))

      {:ok, %{status: :cancelled, worker_pid: nil}}
    end
  end
end
