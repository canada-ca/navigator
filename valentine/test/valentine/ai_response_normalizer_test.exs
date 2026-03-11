defmodule Valentine.AIResponseNormalizerTest do
  use ValentineWeb.ConnCase

  alias Valentine.AIResponseNormalizer
  alias Valentine.Composer.Threat

  describe "threat_from_json/1" do
    test "normalizes scalar list fields" do
      threat =
        AIResponseNormalizer.threat_from_json(%{
          "threat_source" => "a malicious user",
          "prerequisites" => "with access",
          "threat_action" => "modify content",
          "threat_impact" => "unauthorized changes",
          "impacted_goal" => "integrity",
          "impacted_assets" => "private repositories",
          "stride" => "tampering"
        })

      assert %Threat{} = threat
      assert threat.impacted_goal == ["integrity"]
      assert threat.impacted_assets == ["private repositories"]
      assert threat.stride == [:tampering]
    end
  end

  describe "normalize_controls/1" do
    test "normalizes a single control map" do
      assert AIResponseNormalizer.normalize_controls(%{
               control: "AC-1",
               name: "Policy",
               rational: "Because"
             }) == [
               %{"control" => "AC-1", "name" => "Policy", "rational" => "Because"}
             ]
    end

    test "normalizes a list of mixed-key controls" do
      assert AIResponseNormalizer.normalize_controls([
               %{control: "AC-1", name: "Policy", rational: "Because"},
               %{"control" => "AC-2", "name" => "Accounts", "rational" => "Needed"}
             ]) == [
               %{"control" => "AC-1", "name" => "Policy", "rational" => "Because"},
               %{"control" => "AC-2", "name" => "Accounts", "rational" => "Needed"}
             ]
    end
  end
end
