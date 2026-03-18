defmodule Valentine.RepoAnalysis.RecoveryTest do
  use ExUnit.Case, async: false

  import Mock

  alias Valentine.RepoAnalysis.Recovery

  setup do
    repo_analysis_config = Application.get_env(:valentine, :repo_analysis, [])

    if pid = Process.whereis(Recovery) do
      GenServer.stop(pid, :normal)
    end

    on_exit(fn ->
      if pid = Process.whereis(Recovery) do
        GenServer.stop(pid, :normal)
      end

      Application.put_env(:valentine, :repo_analysis, repo_analysis_config)
    end)

    :ok
  end

  describe "scheduling" do
    test "runs recovery immediately and schedules the next sweep when enabled" do
      Application.put_env(
        :valentine,
        :repo_analysis,
        Keyword.merge(Application.get_env(:valentine, :repo_analysis, []),
          recovery_interval_ms: 25
        )
      )

      test_pid = self()

      with_mock Valentine.RepoAnalysis, [:passthrough],
        recover_stale_jobs: fn ->
          send(test_pid, :recover_stale_jobs_called)
          0
        end do
        start_supervised!(Recovery)

        assert_receive :recover_stale_jobs_called, 200
        assert_receive :recover_stale_jobs_called, 200
      end
    end

    test "does not schedule repeated sweeps when the interval is disabled" do
      Application.put_env(
        :valentine,
        :repo_analysis,
        Keyword.merge(Application.get_env(:valentine, :repo_analysis, []),
          recovery_interval_ms: 0
        )
      )

      test_pid = self()

      with_mock Valentine.RepoAnalysis, [:passthrough],
        recover_stale_jobs: fn ->
          send(test_pid, :recover_stale_jobs_called)
          0
        end do
        start_supervised!(Recovery)

        assert_receive :recover_stale_jobs_called, 200
        refute_receive :recover_stale_jobs_called, 100
      end
    end
  end

  describe "lifecycle" do
    test "registers the named process on startup and unregisters it on shutdown" do
      Application.put_env(
        :valentine,
        :repo_analysis,
        Keyword.merge(Application.get_env(:valentine, :repo_analysis, []),
          recovery_interval_ms: 0
        )
      )

      test_pid = self()

      with_mock Valentine.RepoAnalysis, [:passthrough],
        recover_stale_jobs: fn ->
          send(test_pid, :recover_stale_jobs_called)
          0
        end do
        pid = start_supervised!(Recovery)
        monitor_ref = Process.monitor(pid)

        assert_receive :recover_stale_jobs_called, 200
        assert Process.whereis(Recovery) == pid

        GenServer.stop(pid, :normal)

        assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 200
        refute Process.whereis(Recovery)
      end
    end
  end
end
