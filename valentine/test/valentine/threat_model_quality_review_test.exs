defmodule Valentine.ThreatModelQualityReviewTest do
  use Valentine.DataCase

  import Mock
  import Valentine.ComposerFixtures

  alias Valentine.Composer
  alias Valentine.ThreatModelQualityReview
  alias Valentine.ThreatModelQualityReview.Runner
  alias Valentine.ThreatModelQualityReview.Snapshot

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

  describe "start_review/2" do
    test "creates a queued review run" do
      workspace = workspace_fixture(%{owner: "owner-1"})

      assert {:ok, run} = ThreatModelQualityReview.start_review(workspace.id, workspace.owner)

      assert run.workspace_id == workspace.id
      assert run.owner == workspace.owner
      assert run.status == :queued
      assert run.progress_message == "Queued for threat model quality review"

      persisted = Composer.get_threat_model_quality_review_run!(run.id)
      assert persisted.runtime_agent_id == ThreatModelQualityReview.runtime_agent_id(run.id)
    end

    test "rejects a duplicate active review" do
      workspace = workspace_fixture(%{owner: "owner-1"})

      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :reviewing
      })

      assert {:error, :already_running} =
               ThreatModelQualityReview.start_review(workspace.id, workspace.owner)
    end
  end

  describe "cancel_for_owner/2" do
    test "cancels a queued review with no live runtime" do
      run =
        threat_model_quality_review_run_fixture(%{
          owner: "owner-1",
          status: :queued,
          runtime_agent_id: nil,
          cancel_requested_at: nil,
          completed_at: nil
        })

      assert {:ok, cancelled} = ThreatModelQualityReview.cancel_for_owner(run.id, "owner-1")
      assert cancelled.status == :cancelled
      assert %DateTime{} = cancelled.cancel_requested_at
      assert %DateTime{} = cancelled.completed_at
    end
  end

  describe "retry_for_owner/2" do
    test "creates a new queued run for a completed review" do
      workspace = workspace_fixture(%{owner: "owner-1"})

      run =
        threat_model_quality_review_run_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          status: :completed,
          completed_at: DateTime.utc_now()
        })

      assert {:ok, retried} = ThreatModelQualityReview.retry_for_owner(run.id, workspace.owner)
      assert retried.id != run.id
      assert retried.workspace_id == workspace.id
      assert retried.status == :queued
    end
  end

  describe "recover_stale_runs/0" do
    test "marks stale running reviews as timed out" do
      stale_run =
        threat_model_quality_review_run_fixture(%{
          status: :reviewing,
          last_heartbeat_at: DateTime.add(DateTime.utc_now(), -900, :second),
          completed_at: nil,
          failure_reason: nil
        })

      recent_run =
        threat_model_quality_review_run_fixture(%{
          status: :assembling_context,
          last_heartbeat_at: DateTime.add(DateTime.utc_now(), -30, :second)
        })

      assert ThreatModelQualityReview.recover_stale_runs() == 1

      assert Composer.get_threat_model_quality_review_run!(stale_run.id).status == :timed_out

      assert Composer.get_threat_model_quality_review_run!(recent_run.id).status ==
               :assembling_context
    end
  end

  describe "Snapshot.build/1" do
    test "loads normalized workspace content" do
      workspace = workspace_fixture(%{owner: "owner-1"})

      _application_information =
        application_information_fixture(%{
          workspace_id: workspace.id,
          content: "Application details"
        })

      _architecture =
        architecture_fixture(%{workspace_id: workspace.id, content: "Architecture details"})

      threat = threat_fixture(%{workspace_id: workspace.id, threat_source: "external attacker"})

      assumption =
        assumption_fixture(%{workspace_id: workspace.id, content: "Assume trusted admin access"})

      mitigation = mitigation_fixture(%{workspace_id: workspace.id, content: "Enable MFA"})
      _evidence = evidence_fixture(%{workspace_id: workspace.id, name: "Evidence item"})

      assert snapshot = Snapshot.build(workspace.id)
      assert snapshot.workspace.id == workspace.id
      assert snapshot.application_information == "Application details"
      assert snapshot.architecture == "Architecture details"
      assert Enum.any?(snapshot.threats, &(&1.id == threat.id))
      assert Enum.any?(snapshot.assumptions, &(&1.id == assumption.id))
      assert Enum.any?(snapshot.mitigations, &(&1.id == mitigation.id))
      assert is_list(snapshot.dfd.nodes)
      assert is_list(snapshot.dfd.edges)
    end
  end

  describe "Runner.run/1" do
    test "persists structured findings and completes the run" do
      workspace = workspace_fixture(%{owner: "owner-1"})
      _threat = threat_fixture(%{workspace_id: workspace.id})

      run =
        threat_model_quality_review_run_fixture(%{
          workspace_id: workspace.id,
          owner: workspace.owner,
          status: :queued
        })

      mock_result = %Valentine.ThreatModelQualityReview.Generator.ReviewResult{
        findings: [
          %{
            title: "Potential duplicate threats",
            category: :duplicate_threat,
            severity: :medium,
            rationale: "Two threats substantially overlap.",
            suggested_action: "Consolidate the duplicate threats.",
            metadata: %{"threat_ids" => ["one", "two"]}
          }
        ]
      }

      with_mock Valentine.ThreatModelQualityReview.Generator,
        review: fn _snapshot, _model_spec, _opts -> mock_result end do
        assert :ok = Runner.run(run.id)
      end

      persisted_run = Composer.get_threat_model_quality_review_run!(run.id, [:findings])
      assert persisted_run.status == :completed
      assert persisted_run.result_summary["finding_count"] == 1
      assert length(persisted_run.findings) == 1
      assert hd(persisted_run.findings).title == "Potential duplicate threats"
    end
  end
end
