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
    Review repository documentation and source structure, then produce a high-signal first-pass threat model that reads like a senior security engineer wrote it.

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

    Quality bar:
    - Prefer one repo-specific threat over three generic application-security threats.
    - Do not default to generic web-app issues like SQL injection, XSS, CSRF, SSRF, or RCE unless the repository evidence strongly supports them.
    - Prefer threats tied to the repo's actual auth model, secret handling, CI/CD, infrastructure, persistence, external integrations, and deployment shape.
    - Use realistic threat actors such as anonymous user, authenticated user, external attacker with leaked URL, malicious maintainer, compromised CI runner, operator, or attacker with stolen token.
    - Make every threat a concrete abuse case with a specific prerequisite, action, and impact.
    - Avoid filler phrases like "may attempt to" or "could potentially" when a sharper statement is possible.
    - Avoid repeating the same generic mitigation across multiple threats unless it is truly the right control.
    - Mitigations must be actionable and specific enough that an engineer could implement them.

    Content guidance:
    - `application_information` should summarize what the system does, who uses it, what sensitive data it handles, and which security properties matter most.
    - `architecture` should summarize the runtime components, storage, crypto, trust boundaries, deployment path, automation, and notable external dependencies.
    - `assumptions` should be security-relevant and testable, not generic statements about software existing.
    - `mitigations` should prefer exact controls visible in the repo or clear missing controls implied by the design.
    - `threats` should cover the most material risks first and should map back to DFD components.
    - The DFD should separate external actors from internal processes and data stores, and should reflect the likely direction of real flows.

    Threat field grammar:
    - Every threat must read cleanly when rendered as: "A/An [threat_source] [prerequisites] can [threat_action], which leads to [threat_impact], resulting in reduced [impacted_goal], negatively impacting [impacted_assets]."
    - Draft each threat so the three parts play different roles: `threat_action` is the abuse step, `threat_impact` is the resulting harm, and `impacted_assets` is the list of concrete things harmed.
    - After drafting each threat, read the fully rendered sentence once and rewrite it if the action, impact, and assets repeat the same nouns or say the same thing twice.
    - `threat_source` must be a concise actor phrase only, with no article and no trailing punctuation. Good: "external attacker with a leaked secret URL", "malicious maintainer", "compromised CI runner". Bad: "A DevOps misconfiguration.", "Dynamic infrastructure changes", "user credentials are weak".
    - `prerequisites` must be a dependency or condition phrase, not a standalone sentence. It should usually start with "with", "who", "when", "after", or "by" and must not end with punctuation. Good: "with access to application logs", "when one-time URLs are stored in browser history". Bad: "Dynamic infrastructure changes without proper testing or validation.".
    - `threat_action` must be a concrete verb phrase describing what the actor does, with no subject and no modal verbs. It should focus on the step the actor takes, not the downstream harm. Good: "retrieve a secret before the intended recipient", "change database configuration to disable encryption", "write plaintext message contents to development logs". Bad: "Configuration changes leading to an insecure database", "cause sensitive data exposure in logs".
    - `threat_impact` must be the direct consequence of the action, written as a concise result phrase with no leading article and no trailing punctuation. It should name the security harm, not restate the action or just rename the asset. Good: "unauthorized disclosure of shared secret data", "storage of sensitive data without effective encryption", "loss of service availability during incident recovery". Bad: "secrets are exposed in logs", "sensitive data exposure", "logged plaintext secrets".
    - `impacted_goal` must be short security property labels like "confidentiality", "integrity", or "availability", not full sentences.
    - `impacted_assets` must name the specific asset or component harmed, such as "one-time secret URLs", "DynamoDB configuration", "KMS key usage", or "application audit trail".
    - `impacted_assets` must be concrete nouns only. Do not put outcome words like "exposure", "leakage", "loss", "compromise", or "breach" in this field. Bad: "sensitive data exposure", "credential leakage". Good: "encrypted message content", "development logs", "shared secret data".
    - Do not put periods at the end of `threat_source`, `prerequisites`, `threat_action`, or `threat_impact`.
    - Do not use plural or abstract actor labels when a specific singular actor is possible.
    - Prefer one or two precise `impacted_assets` over a long mixed list.

    Threat examples:
    - Good threat decomposition:
      threat_source: "external attacker"
      prerequisites: "with access to an unexpired secret URL from logs, browser history, or referrer leakage"
      threat_action: "retrieve the secret before the intended recipient"
      threat_impact: "unauthorized disclosure of sensitive shared content"
      impacted_goal: ["confidentiality"]
      impacted_assets: ["one-time secret URLs", "shared secret data"]
    - Good threat decomposition:
      threat_source: "operator"
      prerequisites: "when infrastructure changes are deployed without review or validation"
      threat_action: "apply a DynamoDB or KMS configuration that weakens encryption or retention guarantees"
      threat_impact: "storage of secrets with ineffective protection or deletion behavior"
      impacted_goal: ["confidentiality", "integrity"]
      impacted_assets: ["DynamoDB configuration", "KMS integration", "shared secret data"]
    - Good threat decomposition:
      threat_source: "operator"
      prerequisites: "when development logging captures decrypted message payloads during troubleshooting"
      threat_action: "write plaintext message contents to development logs"
      threat_impact: "unauthorized disclosure of encrypted message content to anyone who can read those logs"
      impacted_goal: ["confidentiality"]
      impacted_assets: ["development logs", "encrypted message content"]
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

    Analysis instructions:
    - Start by inferring the product or service the repository implements.
    - Identify the security-relevant components actually supported by the repo: clients, APIs, workers, datastores, queues, KMS/crypto, CI/CD, infrastructure, external services, and privileged operators.
    - Prefer details from README files, environment examples, Dockerfiles, Compose files, CI workflows, IaC, auth code, persistence code, crypto code, and deployment config.
    - If a risk is not supported by repository evidence, leave it out.
    - If the repo suggests a one-time secret, token, URL, workflow, or infrastructure pattern, model the abuse case specific to that pattern rather than falling back to generic web-app threats.
    - Keep the output opinionated and specific. Weak example: "An attacker may access the application." Strong example: "An attacker who obtains a one-time secret URL from logs, browser history, or referrer leakage can retrieve the secret before the intended recipient."
    - Keep assumptions and mitigations tightly connected to the threats. Avoid standalone platitudes.
    - Prefer 6-12 high-value threats over a longer list of repetitive or low-signal ones.
    - When multiple components exist, make sure the DFD and threat list tell the same story.

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
              "threat_source" => %{
                "type" => "string",
                "description" =>
                  "Actor phrase only. No article, no trailing punctuation. Example: external attacker with a leaked secret URL"
              },
              "prerequisites" => %{
                "type" => "string",
                "description" =>
                  "Condition phrase that usually starts with with, who, when, after, or by. Not a full sentence. No trailing punctuation."
              },
              "threat_action" => %{
                "type" => "string",
                "description" =>
                  "Concrete verb phrase describing the actor's abuse step. Focus on what the actor does, not the downstream harm. No subject. No modal verbs. No trailing punctuation."
              },
              "threat_impact" => %{
                "type" => "string",
                "description" =>
                  "Direct consequence phrase of the threat action. Describe the security harm, not the action again and not a vague label like sensitive data exposure. No trailing punctuation."
              },
              "impacted_goal" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" =>
                  "Short security property labels such as confidentiality, integrity, availability, accountability, or authentication"
              },
              "impacted_assets" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" =>
                  "Specific technical assets or components affected by the threat. Use concrete nouns only, not effect labels like exposure, leakage, loss, compromise, or breach"
              },
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
