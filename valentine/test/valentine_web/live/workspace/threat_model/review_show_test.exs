defmodule ValentineWeb.WorkspaceLive.ThreatModel.ReviewShowTest do
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

  test "displays grouped findings for a completed review", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "some owner"})

    run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :completed,
        progress_message: "Threat model quality review completed with 1 findings",
        completed_at: DateTime.utc_now()
      })

    _finding =
      threat_model_quality_review_finding_fixture(%{
        run_id: run.id,
        title: "Potential duplicate threats",
        category: :duplicate_threat,
        severity: :high,
        rationale: "Two threats substantially overlap.",
        suggested_action: "Merge or rewrite the overlapping threats."
      })

    conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

    {:ok, _live, html} =
      live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews/#{run.id}")

    assert html =~ "Threat model quality review"
    assert html =~ "Review run"
    assert html =~ "1 finding"
    assert html =~ "Review details"
    assert html =~ "Potential duplicate threats"
    assert html =~ "#severity-high"
    assert html =~ "High"
    assert html =~ "Duplicate threat"
    assert html =~ "Show rationale and next step"
    assert html =~ "Suggested next action"
  end

  test "shows an explicit no findings state", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "some owner"})

    run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :completed,
        progress_message: "Threat model quality review completed with no actionable findings",
        completed_at: DateTime.utc_now()
      })

    conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

    {:ok, _live, html} =
      live(conn, ~p"/workspaces/#{workspace.id}/threat_model/reviews/#{run.id}")

    assert html =~ "No actionable findings"
  end
end
