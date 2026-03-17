defmodule ValentineWeb.Helpers.ThreatModelReportHelper do
  @moduledoc """
  Shared formatting helpers used by the HTML and Markdown threat model reports.

  Only behavior that is semantically identical across both renderers should live
  here. Output-format-specific concerns stay in the report components.
  """

  alias ValentineWeb.Helpers.DisplayHelper

  def impacted_assets(threats) do
    threats
    |> Enum.filter(&(&1.impacted_assets not in [[], nil]))
    |> Enum.reduce(%{}, fn threat, acc ->
      Enum.reduce(threat.impacted_assets, acc, fn asset, inner_acc ->
        Map.update(inner_acc, asset, [threat.numeric_id], &(&1 ++ [threat.numeric_id]))
      end)
    end)
    |> Enum.with_index()
  end

  def normalize_value(value), do: DisplayHelper.enum_label(value) || ""

  def normalize_type(value, "true"), do: normalize_value(value) <> " (Out of scope)"
  def normalize_type(value, _out_of_scope), do: normalize_value(value)

  def stride_to_letter(nil), do: ""

  def stride_to_letter(data) do
    data
    |> Enum.map(&Atom.to_string/1)
    |> Enum.map(&String.upcase/1)
    |> Enum.map(&String.first/1)
    |> Enum.join()
  end
end
