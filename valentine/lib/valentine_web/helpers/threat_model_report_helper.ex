defmodule ValentineWeb.Helpers.ThreatModelReportHelper do
  @moduledoc """
  Shared formatting helpers used by the HTML and Markdown threat model reports.

  Only behavior that is semantically identical across both renderers should live
  here. Output-format-specific concerns stay in the report components.
  """

  alias Valentine.Composer.DeliberateThreatLevel
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

  def report_tags(nil), do: []

  def report_tags(tags) do
    tags
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  def report_tags_text(tags) do
    tags
    |> report_tags()
    |> Enum.join(", ")
  end

  def deduplicated_tag_comments(nil, _tags), do: nil

  def deduplicated_tag_comments(comments, tags) do
    if comments_match_tags?(comments, tags), do: nil, else: comments
  end

  def threat_agent_td_level_label(nil), do: DisplayHelper.enum_label(nil) || "Not set"

  def threat_agent_td_level_label(value) do
    DeliberateThreatLevel.label(value) || DisplayHelper.enum_label(value) || "Not set"
  end

  def stride_to_letter(nil), do: ""

  def stride_to_letter(data) do
    data
    |> Enum.map(&Atom.to_string/1)
    |> Enum.map(&String.upcase/1)
    |> Enum.map(&String.first/1)
    |> Enum.join()
  end

  defp comments_match_tags?(comments, tags) do
    normalized_tags = report_tags(tags)

    normalized_comments =
      comments
      |> String.replace(~r/<[^>]*>/, "\n")
      |> String.split(~r/[\n,;]+/)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.trim(&1, "*-_`[]()"))
      |> Enum.reject(&(&1 == ""))

    normalized_tags != [] and normalized_comments == normalized_tags
  end
end
