defmodule Valentine.ControlCategorizer do
  @moduledoc false

  require Logger

  alias Valentine.AIProvider
  alias Valentine.AIResponseNormalizer
  alias Valentine.Composer

  import ReqLLM.Context

  @type entity_type :: :assumption | :mitigation

  def suggest(entity_type, entity) when entity_type in [:assumption, :mitigation] do
    prompts = prompts(entity_type, entity)
    context = ReqLLM.Context.new([system(prompts.system), user(prompts.user)])

    result =
      ReqLLM.generate_object!(
        AIProvider.model_spec("ControlCategorizer"),
        context,
        json_schema(entity_type),
        AIProvider.request_opts("ControlCategorizer")
      )

    {:ok, normalize_response(result)}
  rescue
    error ->
      Logger.error("[ControlCategorizer] Error during control categorization",
        entity_type: entity_type,
        error: inspect(error),
        message: Exception.message(error),
        stacktrace: __STACKTRACE__
      )

      {:error, Exception.message(error)}
  end

  def normalize_response(response) when is_map(response) do
    controls = Map.get(response, "controls") || Map.get(response, :controls)

    controls
    |> AIResponseNormalizer.normalize_controls()
    |> Enum.sort_by(& &1["control"])
  end

  def selected_tags(controls) when is_map(controls) do
    controls
    |> Enum.filter(fn {_control, selected} -> selected == "true" end)
    |> Enum.map(fn {control, _selected} -> control end)
  end

  def save_tags(:assumption, assumption, tags) do
    Composer.update_assumption(assumption, %{tags: (assumption.tags || []) ++ tags})
  end

  def save_tags(:mitigation, mitigation, tags) do
    Composer.update_mitigation(mitigation, %{tags: (mitigation.tags || []) ++ tags})
  end

  def prompts(:assumption, assumption) do
    %{
      system: """
      You are an expert in NIST security controls. You will be given one or more threat statements from a threat modeling process, an assumption that shapes the model, and any linked mitigations that add context. Your task is to categorize the assumption based on the NIST security controls that are most relevant to validating, governing, or compensating for that assumption.
      """,
      user: """
      Please suggest up to five NIST controls that are most relevant to this assumption. Please also provide a rationale for why each control applies.

      Threat statements:
      #{format_threats(assumption.threats)}

      Linked mitigations:
      #{format_contents(assumption.mitigations)}

      Assumption:
      #{assumption.content}

      Comments about this assumption:
      #{optional_text(assumption.comments)}

      Tags for this assumption (note this may already include NIST controls; do not repeat them):
      #{format_tags(assumption.tags)}
      """
    }
  end

  def prompts(:mitigation, mitigation) do
    %{
      system: """
      You are an expert in NIST security controls. You will be given one or more threat statements from a threat modeling process and a mitigation intended to address those threats. Your task is to categorize the mitigation based on the NIST security controls it would help satisfy.
      """,
      user: """
      Please suggest up to five NIST controls that the implementation of this mitigation would help satisfy. Please also provide a rationale for why each control applies.

      Threat statements:
      #{format_threats(mitigation.threats)}

      Mitigation:
      #{mitigation.content}

      Comments about this mitigation:
      #{optional_text(mitigation.comments)}

      Tags for this mitigation (note this may already include NIST controls; do not repeat them):
      #{format_tags(mitigation.tags)}
      """
    }
  end

  defp json_schema(entity_type) do
    entity_name = Atom.to_string(entity_type)

    %{
      "type" => "object",
      "properties" => %{
        "controls" => %{
          "type" => "array",
          "description" =>
            "A list of up to five NIST controls and their rationales. Always return a JSON array, even when there is only one control.",
          "items" => %{
            "type" => "object",
            "description" => "A NIST control and the rationale for selecting it",
            "properties" => %{
              "control" => %{
                "type" => "string",
                "description" => "The control ID as a string, for example AC-1, AC-2, or SA-11.1."
              },
              "name" => %{
                "type" => "string",
                "description" =>
                  "The control name, for example 'Account Management | Automated System Account Management'."
              },
              "rational" => %{
                "type" => "string",
                "description" =>
                  "A short rationale explaining why this control applies to the #{entity_name}."
              }
            },
            "required" => ["control", "name", "rational"],
            "additionalProperties" => false
          }
        }
      },
      "required" => ["controls"],
      "additionalProperties" => false
    }
  end

  defp format_threats(threats) do
    threats
    |> List.wrap()
    |> Enum.map_join("\n", fn threat ->
      "START:#{Composer.Threat.show_statement(threat)}END"
    end)
    |> optional_text()
  end

  defp format_contents(records) do
    records
    |> List.wrap()
    |> Enum.map_join("\n", & &1.content)
    |> optional_text()
  end

  defp format_tags(tags) do
    tags
    |> List.wrap()
    |> Enum.join(", ")
    |> optional_text()
  end

  defp optional_text(value) when value in [nil, ""], do: "No content available"
  defp optional_text(value), do: value
end
