defmodule Valentine.ThreatModelQualityReview.GeneratorTest do
  use ExUnit.Case, async: true

  import Mock

  alias Valentine.ThreatModelQualityReview.Generator

  test "runs fixed segment prompts, normalizes wording, and merges overlapping findings" do
    snapshot = %{
      workspace: %{id: "workspace-1", name: "Example workspace"},
      application_information: "Application information",
      architecture: "Architecture",
      dfd: %{nodes: [], edges: []},
      threats: [],
      assumptions: [],
      mitigations: [],
      evidence: []
    }

    Process.put(:review_segment_call_count, 0)

    with_mock ReqLLM,
      generate_object!: fn _model_spec, _context, _schema, opts ->
        count = Process.get(:review_segment_call_count, 0)
        Process.put(:review_segment_call_count, count + 1)

        assert opts[:temperature] == 0.0

        case count do
          0 ->
            %{
              "findings" => [
                %{
                  "title" => "Possible duplicate threat statements",
                  "category" => "duplicate_threat",
                  "severity" => "high",
                  "rationale" => "Threats 1 and 2 appear to describe the same attacker behavior.",
                  "suggested_action" => "Deduplicate the threats.",
                  "metadata" => %{"threat_ids" => ["threat-2", "threat-1"]}
                },
                %{
                  "title" => "Weak STRIDE coverage",
                  "category" => "stride_gap",
                  "severity" => "medium",
                  "rationale" => "Availability threats are missing.",
                  "suggested_action" => "Review denial-of-service coverage.",
                  "metadata" => %{"stride" => ["denial_of_service"]}
                },
                %{
                  "title" => "Duplicate threats",
                  "category" => "duplicate_threat",
                  "severity" => "medium",
                  "rationale" => "Two threats overlap around the same actor and impact.",
                  "suggested_action" => "Consolidate the threats.",
                  "metadata" => %{"threat_ids" => ["threat-1", "threat-2"]}
                }
              ]
            }

          1 ->
            %{
              "findings" => [
                %{
                  "title" => "Orphaned mitigation",
                  "category" => "orphaned_mitigation",
                  "severity" => "low",
                  "rationale" => "The mitigation is not linked.",
                  "suggested_action" => "Link the mitigation to a threat.",
                  "metadata" => %{"mitigation_ids" => ["mitigation-1"]}
                }
              ]
            }

          2 ->
            %{
              "findings" => [
                %{
                  "title" => "Contradictory model artifacts",
                  "category" => "artifact_contradiction",
                  "severity" => "high",
                  "rationale" => "The DFD and architecture disagree on data storage.",
                  "suggested_action" => "Reconcile the diagram and architecture narrative.",
                  "metadata" => %{"node_ids" => ["node-1"]}
                }
              ]
            }

          _ ->
            raise "unexpected segment call"
        end
      end do
      result = Generator.review(snapshot, "openai:test-model", [])

      assert Enum.map(result.findings, & &1.category) == [
               :duplicate_threat,
               :stride_gap,
               :orphaned_mitigation,
               :artifact_contradiction
             ]

      assert Enum.map(result.findings, & &1.severity) == [:high, :medium, :low, :high]

      assert Enum.map(result.findings, & &1.metadata["segment"]) == [
               "coverage",
               "coverage",
               "linkage",
               "consistency"
             ]

      assert Enum.map(result.findings, & &1.title) == [
               "Potential duplicate threats",
               "Weak STRIDE coverage",
               "Orphaned mitigations",
               "Contradictory model artifacts"
             ]

      assert hd(result.findings).suggested_action ==
               "Merge, rewrite, or remove overlapping threat statements."

      assert hd(result.findings).metadata["merged_count"] == 2
      assert hd(result.findings).metadata["threat_ids"] == ["threat-1", "threat-2"]

      assert hd(result.findings).rationale =~
               "Threats 1 and 2 appear to describe the same attacker behavior."

      assert hd(result.findings).rationale =~
               "Two threats overlap around the same actor and impact."

      assert Process.get(:review_segment_call_count) == 3
    end
  end
end
