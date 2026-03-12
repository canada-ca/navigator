defmodule ValentineWeb.WorkspaceLive.ShowViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  defp create_workspace(_) do
    workspace = workspace_fixture()
    assumption = assumption_fixture(%{workspace_id: workspace.id})
    threat = threat_fixture()
    mitigation = mitigation_fixture()
    %{assumption: assumption, mitigation: mitigation, threat: threat, workspace: workspace}
  end

  describe "Show" do
    setup [:create_workspace]

    test "display workspace name", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Show Workspace"
      assert html =~ workspace.name
    end

    test "displays a get started dashboard if no assumptions, mitigations, or threats exist", %{
      conn: conn
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})
      workspace = workspace_fixture()

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Get started"
    end

    test "display workspace cloud profile", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Profile"
      assert html =~ workspace.cloud_profile
    end

    test "display workspace cloud profile type", %{
      conn: conn,
      assumption: assumption,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{assumption.workspace_id}")

      assert html =~ "Type"
      assert html =~ workspace.cloud_profile_type
    end

    test "display mitigation status", %{conn: conn, mitigation: mitigation} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{mitigation.workspace_id}")

      assert html =~ "Mitigation status"
      assert html =~ "[&quot;Identified&quot;]"
    end

    test "display threat prioritization", %{conn: conn, threat: threat} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{threat.workspace_id}")

      assert html =~ "Threats prioritization"
      assert html =~ "[&quot;High&quot;]"
    end

    test "display threat stride", %{conn: conn, threat: threat} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{threat.workspace_id}")

      assert html =~ "Threat STRIDE"
      assert html =~ "Spoofing"
    end

    test "displays the latest repository import status for the workspace", %{conn: conn} do
      workspace = workspace_fixture(%{owner: "some owner"})
      requested_at = DateTime.add(DateTime.utc_now(), -7_200, :second)
      started_at = DateTime.add(DateTime.utc_now(), -7_140, :second)
      heartbeat_at = DateTime.add(DateTime.utc_now(), -7_080, :second)

      _repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          github_url: "https://github.com/example/platform-api",
          status: :persisting_results,
          progress_message: "Persisting generated threat model artifacts",
          progress_percent: 85,
          requested_at: requested_at,
          started_at: started_at,
          last_heartbeat_at: heartbeat_at,
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

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Repository import"
      assert html =~ "https://github.com/example/platform-api"
      assert html =~ "Persisting generated threat model artifacts"
      assert html =~ "Requested"
      assert html =~ Calendar.strftime(requested_at, "%Y-%m-%d %H:%M")
      assert html =~ "Last heartbeat"
      assert html =~ "2 hours ago"
      assert html =~ "example/platform-api @ main"
      assert html =~ "repo-analysis-collapsible__summary"
      assert html =~ "repo-analysis-collapsible__summary-link"

      assert html =~
               "Generated 4 threats, 2 assumptions, 3 mitigations, 5 components, and 6 flows"

      assert html =~ "View all agent jobs"

      refute html =~
               "<details class=\"repo-analysis-collapsible repo-analysis-collapsible--embedded\" open"
    end

    test "shows recent repository import history for the workspace", %{conn: conn} do
      workspace = workspace_fixture(%{owner: "some owner"})
      latest_requested_at = DateTime.add(DateTime.utc_now(), -3_600, :second)
      latest_started_at = DateTime.add(DateTime.utc_now(), -3_540, :second)
      latest_completed_at = DateTime.add(DateTime.utc_now(), -3_300, :second)
      previous_requested_at = DateTime.add(DateTime.utc_now(), -7_200, :second)
      previous_completed_at = DateTime.add(DateTime.utc_now(), -6_960, :second)

      _latest_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          github_url: "https://github.com/example/platform-api",
          status: :completed,
          progress_message: "Threat model created from GitHub repository",
          progress_percent: 100,
          requested_at: latest_requested_at,
          started_at: latest_started_at,
          completed_at: latest_completed_at
        })

      previous_repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          github_url: "https://github.com/example/platform-api",
          status: :failed,
          progress_message: "Repository analysis failed",
          progress_percent: 100,
          requested_at: previous_requested_at,
          completed_at: previous_completed_at,
          failure_reason: "Git clone timed out",
          repo_full_name: "example/platform-api",
          repo_default_branch: "main",
          result_summary: %{
            threat_count: 1,
            assumption_count: 1,
            mitigation_count: 0,
            component_count: 2,
            flow_count: 1
          }
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _show_live, html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert html =~ "Recent import history"
      assert html =~ "Repository analysis failed"
      assert html =~ Calendar.strftime(previous_requested_at, "%Y-%m-%d %H:%M")
      assert html =~ Calendar.strftime(previous_completed_at, "%Y-%m-%d %H:%M")
      assert html =~ "2 hours ago"
      assert html =~ "Git clone timed out"
      assert html =~ "example/platform-api @ main"
      assert html =~ "Retry import"
      assert html =~ "repo-analysis-history-row"

      assert html =~
               "Generated 1 threats, 1 assumptions, 0 mitigations, 2 components, and 1 flows"

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, show_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert show_live
             |> element("button[phx-value-id=\"#{previous_repo_analysis_agent.id}\"]")
             |> render_click() =~ "Repository analysis queued"

      updated_jobs = Valentine.Composer.list_repo_analysis_agents_by_workspace(workspace.id)
      latest_job = Enum.find(updated_jobs, &(&1.id != previous_repo_analysis_agent.id))

      assert length(updated_jobs) == 3
      assert latest_job
      assert latest_job.id != previous_repo_analysis_agent.id
      assert latest_job.status == :queued
    end

    test "retries the latest failed repository import", %{conn: conn} do
      workspace =
        workspace_fixture(%{
          owner: "some owner",
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

      {:ok, show_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}")

      assert show_live
             |> element("button", "Retry import")
             |> render_click() =~ "Repository analysis queued"

      updated_jobs = Valentine.Composer.list_repo_analysis_agents_by_workspace(workspace.id)
      latest_job = Enum.find(updated_jobs, &(&1.id != repo_analysis_agent.id))

      assert length(updated_jobs) == 2
      assert latest_job
      assert latest_job.id != repo_analysis_agent.id
      assert latest_job.status == :queued
      assert latest_job.github_url == workspace.url
    end
  end
end
