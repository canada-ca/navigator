defmodule Valentine.RepoAnalysisTest do
  use Valentine.DataCase

  alias Valentine.Composer
  alias Valentine.RepoAnalysis
  alias Valentine.RepoAnalysis.Runner

  import ExUnit.CaptureLog
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
  end

  describe "Runner.run/1" do
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
  end
end
