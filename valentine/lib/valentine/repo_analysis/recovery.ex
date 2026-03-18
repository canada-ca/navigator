defmodule Valentine.RepoAnalysis.Recovery do
  @moduledoc false

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state, {:continue, :recover_stale_jobs}}
  end

  @impl true
  def handle_continue(:recover_stale_jobs, state) do
    _ = Valentine.RepoAnalysis.recover_stale_jobs()
    {:noreply, schedule_next_sweep(state)}
  end

  @impl true
  def handle_info(:recover_stale_jobs, state) do
    _ = Valentine.RepoAnalysis.recover_stale_jobs()
    {:noreply, schedule_next_sweep(state)}
  end

  defp schedule_next_sweep(state) do
    interval_ms =
      Application.get_env(:valentine, :repo_analysis, [])
      |> Keyword.get(:recovery_interval_ms, 60_000)

    if is_integer(interval_ms) and interval_ms > 0 do
      Process.send_after(self(), :recover_stale_jobs, interval_ms)
    end

    state
  end
end
