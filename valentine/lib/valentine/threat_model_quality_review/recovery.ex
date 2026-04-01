defmodule Valentine.ThreatModelQualityReview.Recovery do
  @moduledoc false

  use GenServer

  @default_interval_ms 60_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    _ = Valentine.ThreatModelQualityReview.recover_stale_runs()
    schedule_recovery()
    {:ok, state}
  end

  @impl true
  def handle_info(:recover, state) do
    _ = Valentine.ThreatModelQualityReview.recover_stale_runs()
    schedule_recovery()
    {:noreply, state}
  end

  defp schedule_recovery do
    Process.send_after(self(), :recover, recovery_interval_ms())
  end

  defp recovery_interval_ms do
    Application.get_env(:valentine, :threat_model_quality_review, [])
    |> Keyword.get(:recovery_interval_ms, @default_interval_ms)
  end
end
