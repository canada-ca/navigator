defmodule ValentineWeb.Helpers.ThreatModelReportHelperTest do
  use ExUnit.Case, async: true

  alias Valentine.Composer.Threat
  alias ValentineWeb.Helpers.ThreatModelReportHelper

  describe "impacted_assets/1" do
    test "groups impacted assets by asset name and preserves threat ids" do
      threats = [
        %Threat{numeric_id: 1, impacted_assets: ["Database", "User Data"]},
        %Threat{numeric_id: 2, impacted_assets: ["Database"]},
        %Threat{numeric_id: 3, impacted_assets: nil}
      ]

      impacted_assets = ThreatModelReportHelper.impacted_assets(threats)

      assert {{"Database", [1, 2]}, 0} in impacted_assets
      assert {{"User Data", [1]}, 1} in impacted_assets
    end
  end

  describe "normalize_type/2" do
    test "formats out-of-scope types consistently" do
      assert ThreatModelReportHelper.normalize_type("serverless_function", "false") ==
               "Serverless function"

      assert ThreatModelReportHelper.normalize_type("serverless_function", "true") ==
               "Serverless function (Out of scope)"
    end
  end

  describe "report_tags/1" do
    test "removes blanks and duplicates while preserving order" do
      assert ThreatModelReportHelper.report_tags(["AC-1", nil, " ", "AC-1", "SC-7"]) ==
               ["AC-1", "SC-7"]
    end
  end

  describe "report_tags_text/1" do
    test "joins formatted tags for report cells" do
      assert ThreatModelReportHelper.report_tags_text(["AC-1", "SC-7", "AC-1"]) ==
               "AC-1, SC-7"
    end
  end

  describe "threat_agent_td_level_label/1" do
    test "formats deliberate threat level labels and nil values" do
      assert ThreatModelReportHelper.threat_agent_td_level_label(:td4) ==
               "Td4 - Organized Criminal Group"

      assert ThreatModelReportHelper.threat_agent_td_level_label(nil) == "Not set"
    end
  end

  describe "deduplicated_tag_comments/2" do
    test "removes comments that only repeat the tags" do
      assert ThreatModelReportHelper.deduplicated_tag_comments("AC-1, SC-7", ["AC-1", "SC-7"]) ==
               nil
    end

    test "preserves real comments" do
      assert ThreatModelReportHelper.deduplicated_tag_comments(
               "AC-1 is partially implemented",
               ["AC-1", "SC-7"]
             ) == "AC-1 is partially implemented"
    end
  end

  describe "stride_to_letter/1" do
    test "returns STRIDE initials" do
      assert ThreatModelReportHelper.stride_to_letter([:spoofing, :tampering]) == "ST"
      assert ThreatModelReportHelper.stride_to_letter(nil) == ""
    end
  end
end
