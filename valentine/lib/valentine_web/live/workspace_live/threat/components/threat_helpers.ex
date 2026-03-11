defmodule ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers do
  def a_or_an(word, captialize \\ false)
  def a_or_an(nil, capitalize), do: if(capitalize, do: "A", else: "a")

  def a_or_an(word, captialize) do
    word = String.downcase(word)
    first_letter = String.at(word, 0)

    if Regex.match?(~r/[aeiou]/i, first_letter) do
      if captialize do
        "An"
      else
        "an"
      end
    else
      if captialize do
        "A"
      else
        "a"
      end
    end
  end

  def join_list(list, joiner \\ "and")
  def join_list(nil, _joiner), do: ""
  def join_list(item, _joiner) when is_binary(item), do: item
  def join_list([], _joiner), do: ""
  def join_list([item], _joiner), do: to_string(item)
  def join_list([a, b], joiner), do: "#{a} #{joiner} #{b}"

  def join_list(list, joiner) do
    {initial, [last]} = Enum.split(list, -1)
    "#{Enum.join(initial, ", ")}, #{joiner} #{last}"
  end
end
