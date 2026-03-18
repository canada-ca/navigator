defmodule Valentine.RepoAnalysis.Agent do
  @moduledoc false

  use Jido.Agent,
    name: "repo_analysis_agent",
    description: "Runs repository analysis jobs for threat model generation",
    schema: [
      status: [type: :atom, default: :queued],
      repo_analysis_agent_id: [type: :string],
      workspace_id: [type: :string],
      owner: [type: :string],
      github_url: [type: :string],
      worker_pid: [type: :any, default: nil]
    ],
    signal_routes: [
      {"repo_analysis.start", Valentine.RepoAnalysis.Agent.Start},
      {"repo_analysis.cancel", Valentine.RepoAnalysis.Agent.Cancel}
    ]

  defmodule Start do
    @moduledoc false

    use Jido.Action,
      name: "repo_analysis_agent_start",
      description: "Start the supervised repo analysis worker",
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
          Valentine.RepoAnalysis.Runner.run(get_in(context, [:state, :repo_analysis_agent_id]))
        end)

      {:ok, %{status: :running, worker_pid: pid}}
    end
  end

  defmodule Cancel do
    @moduledoc false

    use Jido.Action,
      name: "repo_analysis_agent_cancel",
      description: "Cancel the supervised repo analysis worker",
      schema: []

    def run(_params, context) do
      worker_pid = get_in(context, [:state, :worker_pid])

      if is_pid(worker_pid) and Process.alive?(worker_pid) do
        Process.exit(worker_pid, :kill)
      end

      _ = Valentine.RepoAnalysis.Runner.cancel(get_in(context, [:state, :repo_analysis_agent_id]))

      {:ok, %{status: :cancelled, worker_pid: nil}}
    end
  end
end
