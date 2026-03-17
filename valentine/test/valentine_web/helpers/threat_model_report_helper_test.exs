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

  describe "stride_to_letter/1" do
    test "returns STRIDE initials" do
      assert ThreatModelReportHelper.stride_to_letter([:spoofing, :tampering]) == "ST"
      assert ThreatModelReportHelper.stride_to_letter(nil) == ""
    end
  end
end
