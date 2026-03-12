defmodule ValentineWeb.RepoAnalysisAgentLive.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  describe "Index" do
    test "lists the current user's repo analysis jobs", %{conn: conn} do
      requested_at = DateTime.add(DateTime.utc_now(), -7_200, :second)
      started_at = DateTime.add(DateTime.utc_now(), -7_140, :second)
      completed_at = DateTime.add(DateTime.utc_now(), -6_900, :second)

      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          owner: "agent.owner@localhost",
          requested_at: requested_at,
          started_at: started_at,
          completed_at: completed_at,
          repo_full_name: "example/platform-api",
          repo_default_branch: "main",
          result_summary: %{
            threat_count: 4,
            assumption_count: 2,
            mitigation_count: 3,
            component_count: 5,
            flow_count: 6
          }
        })

      _other_repo_analysis_agent = repo_analysis_agent_fixture(%{owner: "other.owner@localhost"})

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "agent.owner@localhost"})

      {:ok, _index_live, html} = live(conn, ~p"/agents")

      assert html =~ "My Agents"
      assert html =~ repo_analysis_agent.github_url
      assert html =~ "Requested"
      assert html =~ Calendar.strftime(requested_at, "%Y-%m-%d %H:%M")
      assert html =~ "Completed"
      assert html =~ "2 hours ago"
      assert html =~ "example/platform-api @ main"
      assert html =~ "repo-analysis-collapsible__summary"
      assert html =~ "repo-analysis-collapsible__summary-link"
      refute html =~ "<details open"

      assert html =~
               "Generated 4 threats, 2 assumptions, 3 mitigations, 5 components, and 6 flows"

      refute html =~ "other.owner@localhost"
    end

    test "cancels a queued repo analysis job", %{conn: conn} do
      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          owner: "agent.owner@localhost",
          status: :queued,
          progress_message: "Queued for repository analysis"
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "agent.owner@localhost"})

      {:ok, index_live, _html} = live(conn, ~p"/agents")

      assert index_live
             |> element("button", "Terminate")
             |> render_click() =~ "Cancellation requested"

      updated_repo_analysis_agent =
        Valentine.Composer.get_repo_analysis_agent!(repo_analysis_agent.id)

      assert updated_repo_analysis_agent.status == :cancelled
    end

    test "retries a failed repo analysis job", %{conn: conn} do
      workspace =
        workspace_fixture(%{
          owner: "agent.owner@localhost",
          url: "https://github.com/example/platform-api"
        })

      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          github_url: workspace.url,
          status: :failed,
          progress_message: "Repository analysis failed",
          completed_at: DateTime.utc_now()
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, index_live, _html} = live(conn, ~p"/agents")

      assert index_live
             |> element("button", "Retry")
             |> render_click() =~ "Repository analysis queued"

      updated_jobs = Valentine.Composer.list_repo_analysis_agents_by_workspace(workspace.id)
      latest_job = Enum.find(updated_jobs, &(&1.id != repo_analysis_agent.id))

      assert length(updated_jobs) == 2
      assert latest_job
      assert latest_job.id != repo_analysis_agent.id
      assert latest_job.status == :queued
      assert latest_job.github_url == workspace.url
    end

    test "shows relative heartbeat timing for a running repo analysis job", %{conn: conn} do
      heartbeat_at = DateTime.add(DateTime.utc_now(), -7_200, :second)

      repo_analysis_agent_fixture(%{
        owner: "agent.owner@localhost",
        status: :indexing,
        requested_at: DateTime.add(DateTime.utc_now(), -7_500, :second),
        last_heartbeat_at: heartbeat_at,
        progress_message: "Indexing repository documentation and code"
      })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "agent.owner@localhost"})

      {:ok, _index_live, html} = live(conn, ~p"/agents")

      assert html =~ "Last heartbeat"
      assert html =~ "2 hours ago"
    end
  end
end
