defmodule Valentine.Composer.DeliberateThreatLevel do
  @moduledoc false

  @levels [
    td1: "Td1 - Script Kiddie",
    td2: "Td2 - Low-Sophistication Insider",
    td3: "Td3 - Opportunistic External / Contractor Insider",
    td4: "Td4 - Organized Criminal Group",
    td5: "Td5 - Sophisticated Threat Actor",
    td6: "Td6 - Nation-State",
    td7: "Td7 - Peer Nation-State"
  ]

  def values, do: Keyword.keys(@levels)

  def options do
    Enum.map(@levels, fn {value, label} -> {label, value} end)
  end

  def labels do
    Map.new(@levels)
  end

  def label(nil), do: nil
  def label(value), do: Map.get(labels(), value)
end
