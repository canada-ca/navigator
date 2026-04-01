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
    refute html =~ "Run review again"
    refute html =~ "Retry review"
  end

  test "starts a threat model quality review from the landing page", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "some owner"})
    conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

    {:ok, review_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews")

    assert review_live
           |> element("button[phx-click=\"start_threat_model_quality_review\"]")
           |> render_click() =~ "Threat model quality review queued"

    [run | _] =
      Valentine.Composer.list_threat_model_quality_review_runs_by_workspace(workspace.id)

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

    refute Valentine.Composer.get_threat_model_quality_review_run_for_owner(
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
end
