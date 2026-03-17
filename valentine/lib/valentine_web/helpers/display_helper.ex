defmodule ValentineWeb.Helpers.DisplayHelper do
  @moduledoc """
  Shared display-formatting helpers.

  Generic display behavior reused across multiple features, or invoked from
  domain code, belongs here instead of inside feature-scoped LiveView helper
  modules. Feature-specific label maps should stay local and delegate fallback
  formatting to this module.
  """

  def indefinite_article(word, capitalize \\ false)
  def indefinite_article(nil, capitalize), do: if(capitalize, do: "A", else: "a")
  def indefinite_article("", capitalize), do: if(capitalize, do: "A", else: "a")

  def indefinite_article(word, capitalize) when is_binary(word) do
    article =
      word
      |> String.downcase()
      |> String.first()
      |> case do
        first_letter when first_letter in ["a", "e", "i", "o", "u"] -> "an"
        _ -> "a"
      end

    if capitalize, do: String.capitalize(article), else: article
  end

  def join_display_list(list, joiner \\ "and")
  def join_display_list(nil, _joiner), do: ""
  def join_display_list(item, _joiner) when is_binary(item), do: item
  def join_display_list([], _joiner), do: ""
  def join_display_list([item], _joiner), do: to_string(item)
  def join_display_list([left, right], joiner), do: "#{left} #{joiner} #{right}"

  def join_display_list(list, joiner) do
    {initial, [last]} = Enum.split(list, -1)
    "#{Enum.join(initial, ", ")}, #{joiner} #{last}"
  end

  def enum_label(nil), do: nil
  def enum_label(value) when is_atom(value), do: Phoenix.Naming.humanize(value)

  def enum_label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def display_label(value, labels \\ nil)
  def display_label(nil, _labels), do: nil
  def display_label(value, nil), do: default_label(value)

  def display_label(value, labels) when is_map(labels) do
    Map.get(labels, value) || default_label(value)
  end

  def repo_analysis_status_label(status), do: enum_label(status)

  defp default_label(value) when is_atom(value), do: enum_label(value)

  defp default_label(value) when is_binary(value) do
    if String.contains?(value, "_"), do: enum_label(value), else: value
  end
end
