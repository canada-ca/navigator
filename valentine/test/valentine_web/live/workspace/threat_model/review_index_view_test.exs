defmodule ValentineWeb.WorkspaceLive.ThreatModel.ReviewIndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  setup do
    config = Application.get_env(:valentine, :threat_model_quality_review, [])

    Application.put_env(
      :valentine,
      :threat_model_quality_review,
      Keyword.put(config, :start_runtime, false)
    )

    on_exit(fn ->
      Application.put_env(:valentine, :threat_model_quality_review, config)
    end)

    :ok
  end

  test "displays the quality review landing page and history", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "some owner"})

    latest_run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :completed,
        progress_message: "Threat model quality review completed with 2 findings",
        progress_percent: 100,
        requested_at: DateTime.add(DateTime.utc_now(), -3_600, :second),
        completed_at: DateTime.add(DateTime.utc_now(), -3_300, :second),
        result_summary: %{
          finding_count: 2,
          high_severity_count: 1,
          medium_severity_count: 1,
          low_severity_count: 0,
          info_severity_count: 0
        }
      })

    _previous_run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :failed,
        progress_message: "Threat model quality review failed",
        progress_percent: 100,
        requested_at: DateTime.add(DateTime.utc_now(), -7_200, :second),
        completed_at: DateTime.add(DateTime.utc_now(), -6_900, :second),
        failure_reason: "provider timeout"
      })

    conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

    {:ok, _review_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews")

    assert html =~ "Threat model quality review"
    assert html =~ "Review runs"
    assert html =~ "Recent review history"
    assert html =~ "View"
    assert html =~ ~p"/workspaces/#{workspace.id}/threat_model/reviews/#{latest_run.id}"
    assert html =~ "Threat model quality review completed with 2 findings"
    assert html =~ "Retry"
  end

  test "starts a threat model quality review from the landing page", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "some owner"})
    conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

    {:ok, review_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews")

    assert review_live
           |> element("button[phx-click=\"start_threat_model_quality_review\"]")
           |> render_click() =~ "Threat model quality review queued"

    [run | _] =
      Valentine.Composer.AnalysisJobs.list_threat_model_quality_review_runs_by_workspace(
        workspace.id
      )

    assert run.status == :queued
  end

  test "deletes a threat model quality review from the landing page", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "some owner"})

    run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :completed,
        progress_message: "Threat model quality review completed with 1 findings",
        progress_percent: 100,
        requested_at: DateTime.add(DateTime.utc_now(), -3_600, :second),
        completed_at: DateTime.add(DateTime.utc_now(), -3_300, :second)
      })

    conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

    {:ok, review_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews")

    assert review_live
           |> element(
             "button[phx-click=\"delete_threat_model_quality_review\"][phx-value-id=\"#{run.id}\"]"
           )
           |> render_click() =~ "Quality review deleted"

    refute Valentine.Composer.AnalysisJobs.get_threat_model_quality_review_run_for_owner(
             run.id,
             workspace.owner
           )
  end

  test "shows an explicit empty state before any review runs exist", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "some owner"})
    conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

    {:ok, _review_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews")

    assert html =~ "No review runs yet"
    assert html =~ "Run quality review"
  end

  test "reader can inspect history but cannot forge lifecycle actions", %{conn: conn} do
    workspace =
      workspace_fixture(%{
        owner: "workspace-owner",
        permissions: %{"reader@localhost" => "read"}
      })

    run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :completed,
        completed_at: DateTime.utc_now()
      })

    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})
    {:ok, view, html} = live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews")

    assert html =~ "Review runs"
    refute html =~ "Run quality review"
    refute html =~ "phx-click=\"retry_threat_model_quality_review\""
    refute html =~ "phx-click=\"delete_threat_model_quality_review\""

    render_hook(view, "delete_threat_model_quality_review", %{"id" => run.id})
    assert Valentine.Composer.AnalysisJobs.get_threat_model_quality_review_run!(run.id)
  end

  test "writer can manage only their own run while retaining write access", %{conn: conn} do
    workspace =
      workspace_fixture(%{
        owner: "workspace-owner",
        permissions: %{"writer@localhost" => "write"}
      })

    writer_run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: "writer@localhost",
        status: :completed,
        completed_at: DateTime.utc_now()
      })

    owner_run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :completed,
        completed_at: DateTime.utc_now(),
        requested_at: DateTime.add(DateTime.utc_now(), -60, :second)
      })

    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "writer@localhost"})
    {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews")

    assert has_element?(
             view,
             "button[phx-click=\"delete_threat_model_quality_review\"][phx-value-id=\"#{writer_run.id}\"]"
           )

    refute has_element?(
             view,
             "button[phx-click=\"delete_threat_model_quality_review\"][phx-value-id=\"#{owner_run.id}\"]"
           )
  end
end
