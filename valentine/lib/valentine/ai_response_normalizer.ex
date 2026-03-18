defmodule Valentine.AIResponseNormalizer do
  @moduledoc false

  alias Valentine.Composer.Threat

  def threat_from_json(json) when is_map(json) do
    %Threat{
      threat_source: json["threat_source"],
      prerequisites: json["prerequisites"],
      threat_action: json["threat_action"],
      threat_impact: json["threat_impact"],
      impacted_goal: normalize_string_list(Map.get(json, "impacted_goal")),
      impacted_assets: normalize_string_list(Map.get(json, "impacted_assets")),
      stride: normalize_existing_atom_list(Map.get(json, "stride"))
    }
  end

  def normalize_controls(nil), do: []
  def normalize_controls([]), do: []

  def normalize_controls(%{} = control) do
    [normalize_control(control)]
  end

  def normalize_controls(controls) when is_list(controls) do
    controls
    |> Enum.map(&normalize_control/1)
    |> Enum.reject(&is_nil/1)
  end

  def normalize_controls(_), do: []

  def normalize_string_list(nil), do: nil
  def normalize_string_list([]), do: []

  def normalize_string_list(value) when is_binary(value) do
    [value]
  end

  def normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
  end

  def normalize_string_list(value), do: [to_string(value)]

  def normalize_existing_atom_list(nil), do: []

  def normalize_existing_atom_list(values) when is_binary(values) do
    [String.to_existing_atom(values)]
  end

  def normalize_existing_atom_list(values) when is_list(values) do
    Enum.map(values, &String.to_existing_atom(to_string(&1)))
  end

  defp normalize_control(control) when is_map(control) do
    normalized =
      control
      |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)

    %{
      "control" => to_string(Map.get(normalized, "control", "")),
      "name" => to_string(Map.get(normalized, "name", "")),
      "rational" => to_string(Map.get(normalized, "rational", ""))
    }
  end

  defp normalize_control(_), do: nil
end
