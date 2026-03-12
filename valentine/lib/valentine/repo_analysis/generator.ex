defmodule Valentine.RepoAnalysis.Generator do
  @moduledoc false

  import ReqLLM.Context

  defmodule Analysis do
    @enforce_keys [
      :application_information,
      :architecture,
      :assumptions,
      :mitigations,
      :threats,
      :dfd
    ]
    defstruct [
      :application_information,
      :architecture,
      :assumptions,
      :mitigations,
      :threats,
      :dfd
    ]
  end

  def generate(snapshot, github_url, model_spec, opts) do
    context =
      ReqLLM.Context.new([
        system(system_prompt()),
        user(user_prompt(snapshot, github_url))
      ])

    obj = ReqLLM.generate_object!(model_spec, context, json_schema(), opts)

    %Analysis{
      application_information: obj["application_information"] || "",
      architecture: obj["architecture"] || "",
      assumptions: obj["assumptions"] || [],
      mitigations: obj["mitigations"] || [],
      threats: obj["threats"] || [],
      dfd: obj["dfd"] || %{"boundaries" => [], "components" => [], "flows" => []}
    }
  end

  defp system_prompt do
    """
    You are an expert application security architect and threat modeler.
    Review repository documentation and source structure, then produce a concise but useful first-pass threat model.

    Requirements:
    - Infer the application's purpose, major components, trust boundaries, and important data flows.
    - Produce concrete assumptions, mitigations, and threats grounded in the repository contents.
    - Prefer accurate, conservative statements over speculation.
    - If a detail is uncertain, describe it as an assumption rather than a fact.
    - Prefer deployment, configuration, infrastructure, and authentication details that are directly supported by repository files.
    - If repository evidence is weak, keep the DFD smaller and phrase uncertain controls or boundaries as assumptions.
    - For each assumption and mitigation, include `related_threat_indexes` with zero-based indexes into the threats array.
    - Component identifiers in the DFD must be stable slug-like strings.
    - Only include DFD elements that are meaningful for a first-pass review.
    """
  end

  defp user_prompt(snapshot, github_url) do
    docs =
      snapshot.documents
      |> Enum.map(fn %{path: path, content: content} ->
        "FILE: #{path}\n#{String.slice(content, 0, 8000)}"
      end)
      |> Enum.join("\n\n")

    """
    GitHub URL: #{github_url}
    Repository: #{snapshot.repo.full_name}
    Default branch: #{snapshot.default_branch}
    Detected stack hints: #{Enum.join(snapshot.metadata["stack_hints"] || [], ", ")}
    File extension breakdown: #{inspect(snapshot.metadata["languages"] || %{})}
    High-value files: #{Enum.join(snapshot.metadata["priority_paths"] || [], ", ")}

    Directory tree:
    #{snapshot.directory_tree}

    Selected repository files:
    #{docs}
    """
  end

  defp json_schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_information" => %{"type" => "string"},
        "architecture" => %{"type" => "string"},
        "assumptions" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "content" => %{"type" => "string"},
              "related_threat_indexes" => %{
                "type" => "array",
                "items" => %{"type" => "integer", "minimum" => 0}
              }
            },
            "required" => ["content", "related_threat_indexes"],
            "additionalProperties" => false
          }
        },
        "mitigations" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "content" => %{"type" => "string"},
              "related_threat_indexes" => %{
                "type" => "array",
                "items" => %{"type" => "integer", "minimum" => 0}
              }
            },
            "required" => ["content", "related_threat_indexes"],
            "additionalProperties" => false
          }
        },
        "threats" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "threat_source" => %{"type" => "string"},
              "prerequisites" => %{"type" => "string"},
              "threat_action" => %{"type" => "string"},
              "threat_impact" => %{"type" => "string"},
              "impacted_goal" => %{"type" => "array", "items" => %{"type" => "string"}},
              "impacted_assets" => %{"type" => "array", "items" => %{"type" => "string"}},
              "stride" => %{
                "type" => "array",
                "items" => %{
                  "type" => "string",
                  "enum" => [
                    "spoofing",
                    "tampering",
                    "repudiation",
                    "information_disclosure",
                    "denial_of_service",
                    "elevation_of_privilege"
                  ]
                }
              },
              "related_component_ids" => %{
                "type" => "array",
                "items" => %{"type" => "string"}
              }
            },
            "required" => [
              "threat_source",
              "prerequisites",
              "threat_action",
              "threat_impact",
              "impacted_goal",
              "impacted_assets",
              "stride",
              "related_component_ids"
            ],
            "additionalProperties" => false
          }
        },
        "dfd" => %{
          "type" => "object",
          "properties" => %{
            "boundaries" => %{
              "type" => "array",
              "items" => %{
                "type" => "object",
                "properties" => %{
                  "id" => %{"type" => "string"},
                  "label" => %{"type" => "string"},
                  "description" => %{"type" => "string"}
                },
                "required" => ["id", "label", "description"],
                "additionalProperties" => false
              }
            },
            "components" => %{
              "type" => "array",
              "items" => %{
                "type" => "object",
                "properties" => %{
                  "id" => %{"type" => "string"},
                  "label" => %{"type" => "string"},
                  "kind" => %{
                    "type" => "string",
                    "enum" => ["process", "data_store", "external_entity"]
                  },
                  "description" => %{"type" => "string"},
                  "boundary_id" => %{"type" => ["string", "null"]}
                },
                "required" => ["id", "label", "kind", "description", "boundary_id"],
                "additionalProperties" => false
              }
            },
            "flows" => %{
              "type" => "array",
              "items" => %{
                "type" => "object",
                "properties" => %{
                  "source" => %{"type" => "string"},
                  "target" => %{"type" => "string"},
                  "label" => %{"type" => "string"},
                  "description" => %{"type" => "string"}
                },
                "required" => ["source", "target", "label", "description"],
                "additionalProperties" => false
              }
            }
          },
          "required" => ["boundaries", "components", "flows"],
          "additionalProperties" => false
        }
      },
      "required" => [
        "application_information",
        "architecture",
        "assumptions",
        "mitigations",
        "threats",
        "dfd"
      ],
      "additionalProperties" => false
    }
  end
end
