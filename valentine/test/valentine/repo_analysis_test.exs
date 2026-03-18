defmodule Valentine.RepoAnalysisTest do
  use Valentine.DataCase

  alias Valentine.Composer
  alias Valentine.RepoAnalysis
  alias Valentine.RepoAnalysis.Generator.Analysis
  alias Valentine.RepoAnalysis.GitHub.RepoRef
  alias Valentine.RepoAnalysis.GitHub.Snapshot
  alias Valentine.RepoAnalysis.Runner

  import ExUnit.CaptureLog
  import Mock
  import Valentine.ComposerFixtures

  setup do
    repo_analysis_config = Application.get_env(:valentine, :repo_analysis, [])

    Application.put_env(
      :valentine,
      :repo_analysis,
      Keyword.put(repo_analysis_config, :start_runtime, false)
    )

    on_exit(fn ->
      Application.put_env(:valentine, :repo_analysis, repo_analysis_config)
    end)

    :ok
  end

  describe "create_import/2" do
    test "creates a workspace and queued repo analysis job" do
      attrs = %{
        "github_url" => "https://github.com/example/valentine-service",
        "name" => "Imported workspace",
        "cloud_profile" => "CCCS Low Profile for Cloud",
        "cloud_profile_type" => "CSP Full Stack"
      }

      assert {:ok, %{workspace: workspace, repo_analysis_agent: repo_analysis_agent}} =
               RepoAnalysis.create_import("owner-1", attrs)

      assert workspace.name == "Imported workspace"
      assert workspace.url == attrs["github_url"]
      assert workspace.owner == "owner-1"
      assert workspace.cloud_profile == "CCCS Low Profile for Cloud"
      assert workspace.cloud_profile_type == "CSP Full Stack"

      assert repo_analysis_agent.workspace_id == workspace.id
      assert repo_analysis_agent.owner == "owner-1"
      assert repo_analysis_agent.github_url == attrs["github_url"]

      assert repo_analysis_agent.runtime_agent_id ==
               RepoAnalysis.runtime_agent_id(repo_analysis_agent.id)

      assert repo_analysis_agent.progress_message == "Queued for repository analysis"
      assert is_map(repo_analysis_agent.limits)

      persisted_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)
      assert persisted_repo_analysis_agent.workspace_id == workspace.id

      assert persisted_repo_analysis_agent.runtime_agent_id ==
               repo_analysis_agent.runtime_agent_id
    end

    test "infers the workspace name from the GitHub URL when name is omitted" do
      attrs = %{
        "github_url" => "https://github.com/example/platform-api.git"
      }

      assert {:ok, %{workspace: workspace, repo_analysis_agent: repo_analysis_agent}} =
               RepoAnalysis.create_import("owner-1", attrs)

      assert workspace.name == "platform-api"
      assert workspace.url == attrs["github_url"]
      assert repo_analysis_agent.github_url == attrs["github_url"]
    end

    test "returns a changeset error when workspace creation is invalid" do
      assert {:error, %Ecto.Changeset{} = changeset} =
               RepoAnalysis.create_import(nil, %{
                 "github_url" => "https://github.com/example/repo"
               })

      assert "can't be blank" in errors_on(changeset).owner
      assert Composer.list_workspaces() == []
      assert Composer.list_repo_analysis_agents_by_owner("owner-1") == []
    end

    test "returns a changeset error for a non-GitHub URL" do
      assert {:error, %Ecto.Changeset{} = changeset} =
               RepoAnalysis.create_import("owner-1", %{
                 "github_url" => "https://gitlab.com/example/repo"
               })

      assert "Only public GitHub repository URLs are supported" in errors_on(changeset).github_url
      assert Composer.list_workspaces() == []
      assert Composer.list_repo_analysis_agents_by_owner("owner-1") == []
    end

    test "returns a changeset error for an incomplete GitHub URL" do
      assert {:error, %Ecto.Changeset{} = changeset} =
               RepoAnalysis.create_import("owner-1", %{
                 "github_url" => "https://github.com/example"
               })

      assert "GitHub URL must point to a repository" in errors_on(changeset).github_url
    end

    test "returns a changeset error for a private or inaccessible GitHub repository" do
      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "repo-analysis-private-access-test-#{System.unique_integer([:positive])}"
        )

      fake_bin_dir = Path.join(temp_dir, "bin")
      fake_git_path = Path.join(fake_bin_dir, "git")
      original_path = System.get_env("PATH") || ""
      repo_analysis_config = Application.get_env(:valentine, :repo_analysis, [])

      File.mkdir_p!(fake_bin_dir)

      File.write!(
        fake_git_path,
        "#!/bin/sh\nprintf \"fatal: could not read Username for 'https://github.com': terminal prompts disabled\\n\"\nexit 128\n"
      )

      File.chmod!(fake_git_path, 0o755)
      System.put_env("PATH", fake_bin_dir <> ":" <> original_path)

      Application.put_env(
        :valentine,
        :repo_analysis,
        Keyword.merge(repo_analysis_config,
          verify_repo_access: true,
          repo_access_timeout_ms: 100
        )
      )

      on_exit(fn ->
        System.put_env("PATH", original_path)
        Application.put_env(:valentine, :repo_analysis, repo_analysis_config)
        File.rm_rf(temp_dir)
      end)

      assert {:error, %Ecto.Changeset{} = changeset} =
               RepoAnalysis.create_import("owner-1", %{
                 "github_url" => "https://github.com/example/private-repo/pulls"
               })

      assert "Repository is private or inaccessible; only public GitHub repositories are supported" in errors_on(
               changeset
             ).github_url

      assert Composer.list_workspaces() == []
      assert Composer.list_repo_analysis_agents_by_owner("owner-1") == []
    end
  end

  describe "cancel_for_owner/2" do
    test "returns not_found when the job does not belong to the owner" do
      repo_analysis_agent = repo_analysis_agent_fixture(%{owner: "owner-1"})

      assert {:error, :not_found} =
               RepoAnalysis.cancel_for_owner(repo_analysis_agent.id, "owner-2")

      persisted_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)
      assert is_nil(persisted_repo_analysis_agent.cancel_requested_at)
      assert persisted_repo_analysis_agent.status == :queued
    end

    test "cancels a queued job without a live runtime process" do
      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          owner: "owner-1",
          status: :queued,
          runtime_agent_id: nil,
          cancel_requested_at: nil,
          completed_at: nil
        })

      assert {:ok, cancelled_repo_analysis_agent} =
               RepoAnalysis.cancel_for_owner(repo_analysis_agent.id, "owner-1")

      assert cancelled_repo_analysis_agent.id == repo_analysis_agent.id
      assert cancelled_repo_analysis_agent.status == :cancelled
      assert cancelled_repo_analysis_agent.progress_message == "Repository analysis cancelled"
      assert %DateTime{} = cancelled_repo_analysis_agent.cancel_requested_at
      assert %DateTime{} = cancelled_repo_analysis_agent.completed_at

      persisted_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)
      assert persisted_repo_analysis_agent.status == :cancelled
      assert persisted_repo_analysis_agent.progress_message == "Repository analysis cancelled"
      assert %DateTime{} = persisted_repo_analysis_agent.cancel_requested_at
      assert %DateTime{} = persisted_repo_analysis_agent.completed_at
    end
  end

  describe "retry_for_owner/2" do
    test "creates a new queued job for a failed import" do
      workspace = workspace_fixture(%{owner: "owner-1", url: "https://github.com/example/repo"})

      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          github_url: workspace.url,
          status: :failed,
          limits: %{"max_files" => 15},
          failure_reason: "clone failed",
          completed_at: DateTime.utc_now()
        })

      assert {:ok, retried_repo_analysis_agent} =
               RepoAnalysis.retry_for_owner(repo_analysis_agent.id, workspace.owner)

      assert retried_repo_analysis_agent.id != repo_analysis_agent.id
      assert retried_repo_analysis_agent.workspace_id == workspace.id
      assert retried_repo_analysis_agent.owner == workspace.owner
      assert retried_repo_analysis_agent.github_url == workspace.url
      assert retried_repo_analysis_agent.status == :queued
      assert retried_repo_analysis_agent.progress_message == "Queued for repository analysis"
      assert retried_repo_analysis_agent.limits == %{"max_files" => 15}

      persisted_jobs = Composer.list_repo_analysis_agents_by_workspace(workspace.id)

      assert length(persisted_jobs) == 2
      assert Enum.any?(persisted_jobs, &(&1.id == repo_analysis_agent.id))
      assert Enum.any?(persisted_jobs, &(&1.id == retried_repo_analysis_agent.id))
    end

    test "returns already_running when the workspace already has an active import" do
      workspace = workspace_fixture(%{owner: "owner-1", url: "https://github.com/example/repo"})

      repo_analysis_agent_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        github_url: workspace.url,
        status: :queued
      })

      failed_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          github_url: workspace.url,
          status: :failed,
          completed_at: DateTime.utc_now()
        })

      assert {:error, :already_running} =
               RepoAnalysis.retry_for_owner(failed_repo_analysis_agent.id, workspace.owner)
    end

    test "supports repeated reruns for the same workspace after prior reruns complete" do
      workspace =
        workspace_fixture(%{owner: "owner-1", url: "https://github.com/example/repo"})

      completed_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          github_url: workspace.url,
          status: :completed,
          limits: %{"max_files" => 15},
          completed_at: DateTime.utc_now()
        })

      assert {:ok, first_rerun} =
               RepoAnalysis.retry_for_owner(completed_repo_analysis_agent.id, workspace.owner)

      assert first_rerun.workspace_id == workspace.id
      assert first_rerun.github_url == workspace.url
      assert first_rerun.limits == %{"max_files" => 15}
      assert first_rerun.status == :queued

      {:ok, first_rerun} =
        Composer.update_repo_analysis_agent(first_rerun, %{
          status: :completed,
          progress_message: "Threat model created from GitHub repository",
          completed_at: DateTime.utc_now()
        })

      assert {:ok, second_rerun} =
               RepoAnalysis.retry_for_owner(first_rerun.id, workspace.owner)

      jobs = Composer.list_repo_analysis_agents_by_workspace(workspace.id)

      assert length(jobs) == 3
      assert Enum.all?(jobs, &(&1.workspace_id == workspace.id))
      assert Enum.all?(jobs, &(&1.github_url == workspace.url))
      assert second_rerun.id not in [completed_repo_analysis_agent.id, first_rerun.id]
      assert second_rerun.status == :queued
      assert second_rerun.limits == %{"max_files" => 15}
    end
  end

  describe "recover_stale_jobs/0" do
    test "marks stale running jobs as timed out and removes clone directories" do
      clone_dir =
        Path.join(System.tmp_dir!(), "repo-analysis-test-#{System.unique_integer([:positive])}")

      :ok = File.mkdir_p(clone_dir)
      :ok = File.write(Path.join(clone_dir, "tmp.txt"), "tmp")

      stale_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          status: :cloning,
          last_heartbeat_at: DateTime.add(DateTime.utc_now(), -900, :second),
          metadata: %{"clone_dir" => clone_dir},
          completed_at: nil,
          failure_reason: nil
        })

      recent_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          status: :indexing,
          last_heartbeat_at: DateTime.add(DateTime.utc_now(), -30, :second)
        })

      assert RepoAnalysis.recover_stale_jobs() == 1

      timed_out_repo_analysis_agent =
        Composer.get_repo_analysis_agent!(stale_repo_analysis_agent.id)

      assert timed_out_repo_analysis_agent.status == :timed_out
      assert timed_out_repo_analysis_agent.progress_message == "Repository analysis timed out"
      assert timed_out_repo_analysis_agent.failure_reason =~ "No heartbeat received"
      assert %DateTime{} = timed_out_repo_analysis_agent.completed_at
      refute File.exists?(clone_dir)

      unchanged_repo_analysis_agent =
        Composer.get_repo_analysis_agent!(recent_repo_analysis_agent.id)

      assert unchanged_repo_analysis_agent.status == :indexing
    end

    test "uses requested_at fallback when heartbeat timestamps are missing and ignores terminal jobs" do
      stale_requested_at = DateTime.add(DateTime.utc_now(), -900, :second)

      stale_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          status: :queued,
          requested_at: stale_requested_at,
          started_at: nil,
          last_heartbeat_at: nil,
          completed_at: nil,
          failure_reason: nil
        })

      completed_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          status: :completed,
          requested_at: stale_requested_at,
          started_at: nil,
          last_heartbeat_at: nil,
          completed_at: DateTime.utc_now(),
          progress_message: "Threat model created from GitHub repository"
        })

      assert RepoAnalysis.recover_stale_jobs() == 1

      timed_out_repo_analysis_agent =
        Composer.get_repo_analysis_agent!(stale_repo_analysis_agent.id)

      assert timed_out_repo_analysis_agent.status == :timed_out
      assert timed_out_repo_analysis_agent.failure_reason =~ "No heartbeat received"

      unchanged_completed_repo_analysis_agent =
        Composer.get_repo_analysis_agent!(completed_repo_analysis_agent.id)

      assert unchanged_completed_repo_analysis_agent.status == :completed
      assert unchanged_completed_repo_analysis_agent.completed_at
    end
  end

  describe "Runner.run/1" do
    test "marks the job cancelled and cleans up after cancellation is requested mid-run" do
      clone_dir =
        Path.join(
          System.tmp_dir!(),
          "repo-analysis-runner-cancel-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(clone_dir)
      File.write!(Path.join(clone_dir, "partial.txt"), "partial")

      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          github_url: "https://github.com/example/repo",
          status: :queued,
          runtime_agent_id: "runtime-agent-1",
          metadata: %{},
          cancel_requested_at: nil,
          completed_at: nil
        })

      with_mocks([
        {
          Valentine.RepoAnalysis.GitHub,
          [:passthrough],
          clone: fn _repo_ref, repo_analysis_agent_id, _limits ->
            repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent_id)

            {:ok, _repo_analysis_agent} =
              Composer.update_repo_analysis_agent(repo_analysis_agent, %{
                cancel_requested_at: DateTime.utc_now()
              })

            {:ok, clone_dir, %{"clone_dir" => clone_dir, "clone_output" => "cloned"}}
          end,
          build_snapshot: fn _clone_dir, _repo_ref, _limits ->
            flunk("build_snapshot/3 should not run after cancellation is requested")
          end
        },
        {Valentine.Jido, [],
         stop_agent: fn runtime_agent_id ->
           send(self(), {:stop_agent, runtime_agent_id})
           :ok
         end}
      ]) do
        assert :ok = Runner.run(repo_analysis_agent.id)
      end

      updated_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)

      assert updated_repo_analysis_agent.status == :cancelled
      assert updated_repo_analysis_agent.progress_message == "Repository analysis cancelled"
      assert %DateTime{} = updated_repo_analysis_agent.completed_at
      refute File.exists?(clone_dir)
      assert_received {:stop_agent, "runtime-agent-1"}
    end

    test "marks the job failed for an invalid GitHub URL" do
      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          github_url: "https://gitlab.com/example/repo",
          status: :queued,
          failure_reason: nil,
          completed_at: nil
        })

      log =
        capture_log(fn ->
          assert :error = Runner.run(repo_analysis_agent.id)
        end)

      assert log =~ "[RepoAnalysis] job failed"

      failed_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)
      assert failed_repo_analysis_agent.status == :failed
      assert failed_repo_analysis_agent.progress_message == "Repository analysis failed"

      assert failed_repo_analysis_agent.failure_reason =~
               "Only public GitHub repository URLs are supported"

      assert %DateTime{} = failed_repo_analysis_agent.completed_at
    end

    test "marks the job failed and still cleans up the clone directory after downstream failures" do
      clone_dir =
        Path.join(
          System.tmp_dir!(),
          "repo-analysis-runner-failure-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(clone_dir)
      File.write!(Path.join(clone_dir, "partial.txt"), "partial")

      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          github_url: "https://github.com/example/repo",
          status: :queued,
          runtime_agent_id: "runtime-agent-2",
          metadata: %{},
          failure_reason: nil,
          completed_at: nil
        })

      with_mocks([
        {
          Valentine.RepoAnalysis.GitHub,
          [:passthrough],
          clone: fn _repo_ref, _repo_analysis_agent_id, _limits ->
            {:ok, clone_dir, %{"clone_dir" => clone_dir, "clone_output" => "cloned"}}
          end,
          build_snapshot: fn _clone_dir, _repo_ref, _limits ->
            raise "snapshot failed"
          end
        },
        {Valentine.Jido, [],
         stop_agent: fn runtime_agent_id ->
           send(self(), {:stop_agent, runtime_agent_id})
           :ok
         end}
      ]) do
        log =
          capture_log(fn ->
            assert :error = Runner.run(repo_analysis_agent.id)
          end)

        assert log =~ "[RepoAnalysis] job failed"
      end

      failed_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)

      assert failed_repo_analysis_agent.status == :failed
      assert failed_repo_analysis_agent.progress_message == "Repository analysis failed"
      assert failed_repo_analysis_agent.failure_reason == "snapshot failed"
      assert %DateTime{} = failed_repo_analysis_agent.completed_at
      refute File.exists?(clone_dir)
      assert_received {:stop_agent, "runtime-agent-2"}
    end

    test "keeps repo metadata from snapshot enrichment when persistence fails after generation" do
      clone_dir =
        Path.join(
          System.tmp_dir!(),
          "repo-analysis-runner-persist-failure-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(clone_dir)
      File.write!(Path.join(clone_dir, "partial.txt"), "partial")

      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          github_url: "https://github.com/example/repo",
          status: :queued,
          runtime_agent_id: "runtime-agent-3",
          metadata: %{},
          failure_reason: nil,
          completed_at: nil
        })

      repo_ref = %RepoRef{
        owner: "example",
        name: "repo",
        full_name: "example/repo",
        clone_url: "https://github.com/example/repo.git"
      }

      snapshot = %Snapshot{
        repo: repo_ref,
        default_branch: "main",
        directory_tree: "README.md",
        documents: [%{path: "README.md", content: "hello"}],
        metadata: %{
          "stack_hints" => ["Phoenix/Elixir"],
          "priority_paths" => ["README.md"],
          "languages" => %{".ex" => 3}
        }
      }

      analysis = %Analysis{
        application_information: "Generated app info",
        architecture: "Generated architecture",
        assumptions: [],
        mitigations: [],
        threats: [],
        dfd: %{"boundaries" => [], "components" => [], "flows" => []}
      }

      with_mocks([
        {
          Valentine.RepoAnalysis.GitHub,
          [:passthrough],
          parse_public_url!: fn _github_url -> repo_ref end,
          clone: fn _repo_ref, _repo_analysis_agent_id, _limits ->
            {:ok, clone_dir, %{"clone_dir" => clone_dir, "clone_output" => "cloned"}}
          end,
          build_snapshot: fn ^clone_dir, ^repo_ref, _limits ->
            {:ok, snapshot}
          end
        },
        {Valentine.RepoAnalysis.Generator, [],
         generate: fn ^snapshot, _github_url, _model_spec, _opts ->
           send(self(), :generator_called)
           analysis
         end},
        {Valentine.RepoAnalysis.Persister, [],
         persist: fn _workspace_id, ^analysis ->
           raise "persist failed"
         end},
        {Valentine.Jido, [],
         stop_agent: fn runtime_agent_id ->
           send(self(), {:stop_agent, runtime_agent_id})
           :ok
         end}
      ]) do
        log =
          capture_log(fn ->
            assert :error = Runner.run(repo_analysis_agent.id)
          end)

        assert log =~ "[RepoAnalysis] job failed"
      end

      assert_received :generator_called

      failed_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)

      assert failed_repo_analysis_agent.status == :failed
      assert failed_repo_analysis_agent.progress_message == "Repository analysis failed"
      assert failed_repo_analysis_agent.failure_reason == "persist failed"
      assert failed_repo_analysis_agent.repo_full_name == "example/repo"
      assert failed_repo_analysis_agent.repo_default_branch == "main"
      assert failed_repo_analysis_agent.metadata["clone_output"] == "cloned"
      assert failed_repo_analysis_agent.metadata["stack_hints"] == ["Phoenix/Elixir"]
      assert failed_repo_analysis_agent.metadata["priority_paths"] == ["README.md"]
      assert %DateTime{} = failed_repo_analysis_agent.completed_at
      refute File.exists?(clone_dir)
      assert_received {:stop_agent, "runtime-agent-3"}
    end
  end

  describe "Runner.cancel/1" do
    test "cleans up the clone directory and marks the job cancelled" do
      clone_dir =
        Path.join(
          System.tmp_dir!(),
          "repo-analysis-runner-cleanup-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(clone_dir)
      File.write!(Path.join(clone_dir, "partial.txt"), "partial")

      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          status: :indexing,
          metadata: %{"clone_dir" => clone_dir},
          completed_at: nil,
          cancel_requested_at: nil
        })

      assert {:ok, cancelled_repo_analysis_agent} = Runner.cancel(repo_analysis_agent.id)

      assert cancelled_repo_analysis_agent.status == :cancelled
      assert cancelled_repo_analysis_agent.progress_message == "Repository analysis cancelled"
      assert %DateTime{} = cancelled_repo_analysis_agent.completed_at

      persisted_repo_analysis_agent = Composer.get_repo_analysis_agent!(repo_analysis_agent.id)

      assert persisted_repo_analysis_agent.status == :cancelled
      refute File.exists?(clone_dir)
    end
  end
end
