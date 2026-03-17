defmodule ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers do
  @moduledoc """
  Compatibility wrapper for threat-specific call sites.

  Generic display-formatting behavior now lives in
  `ValentineWeb.Helpers.DisplayHelper` and should be consumed from there in new
  code.
  """

  alias ValentineWeb.Helpers.DisplayHelper

  def a_or_an(word, capitalize \\ false), do: DisplayHelper.indefinite_article(word, capitalize)

  def join_list(list, joiner \\ "and"), do: DisplayHelper.join_display_list(list, joiner)
end
