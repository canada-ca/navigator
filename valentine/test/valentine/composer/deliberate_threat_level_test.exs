defmodule Valentine.Composer.DeliberateThreatLevelTest do
  use ExUnit.Case, async: true

  alias Valentine.Composer.DeliberateThreatLevel

  test "returns the seven td values in order" do
    assert DeliberateThreatLevel.values() == [:td1, :td2, :td3, :td4, :td5, :td6, :td7]
  end

  test "returns labeled options for dropdowns" do
    assert DeliberateThreatLevel.options() == [
             {"Td1 - Script Kiddie", :td1},
             {"Td2 - Low-Sophistication Insider", :td2},
             {"Td3 - Opportunistic External / Contractor Insider", :td3},
             {"Td4 - Organized Criminal Group", :td4},
             {"Td5 - Sophisticated Threat Actor", :td5},
             {"Td6 - Nation-State", :td6},
             {"Td7 - Peer Nation-State", :td7}
           ]
  end

  test "returns labels by atom" do
    assert DeliberateThreatLevel.label(:td4) == "Td4 - Organized Criminal Group"
    assert DeliberateThreatLevel.label(:td6) == "Td6 - Nation-State"
  end
end
