defmodule Valentine.MCP.Registry do
  import Valentine.MCP.ToolHelpers, only: [schema: 1, schema: 2]

  alias Valentine.MCP.Tools.Documents
  alias Valentine.MCP.Tools.ThreatModeling
  alias Valentine.MCP.Tools.Workspace

  @stride_values [
    "spoofing",
    "tampering",
    "repudiation",
    "information_disclosure",
    "denial_of_service",
    "elevation_of_privilege"
  ]
  @node_types ["actor", "process", "datastore", "trust_boundary"]

  def tool_definitions do
    Enum.map(tool_specs(), fn %{
                                name: name,
                                description: description,
                                input_schema: input_schema,
                                annotations: annotations
                              } ->
      %{
        name: name,
        title: annotations.title,
        description: description,
        inputSchema: input_schema,
        annotations: annotations
      }
    end)
  end

  def call_tool(name, args, api_key) do
    case Enum.find(tool_specs(), &(&1.name == name)) do
      %{handler: {module, function}, input_schema: input_schema} ->
        case validate_required_arguments(input_schema, args) do
          :ok ->
            case apply(module, function, [args, api_key]) do
              {:ok, content} ->
                {:ok, %{content: content, isError: false}}

              {:tool_error, message} ->
                {:ok, %{content: [%{type: "text", text: message}], isError: true}}
            end

          {:tool_error, message} ->
            {:ok, %{content: [%{type: "text", text: message}], isError: true}}
        end

      nil ->
        {:error, -32602, "Unknown tool: #{name}"}
    end
  rescue
    error in Ecto.NoResultsError ->
      {:ok, %{content: [%{type: "text", text: Exception.message(error)}], isError: true}}

    error in Ecto.InvalidChangesetError ->
      {:ok, %{content: [%{type: "text", text: Exception.message(error)}], isError: true}}

    _error in FunctionClauseError ->
      {:ok, %{content: [%{type: "text", text: "Invalid arguments for #{name}"}], isError: true}}
  end

  defp validate_required_arguments(%{required: required}, args) do
    missing = Enum.reject(required, &Map.has_key?(args, &1))

    case missing do
      [] -> :ok
      _ -> {:tool_error, "Missing required arguments: #{Enum.join(missing, ", ")}"}
    end
  end

  defp tool_specs do
    [
      tool(
        "list_workspaces",
        "List the workspace scoped to the authenticated API key.",
        schema(%{}),
        {Workspace, :list_workspaces},
        :read
      ),
      tool(
        "get_workspace",
        "Get the API key's current workspace.",
        schema(%{}),
        {Workspace, :get_workspace},
        :read
      ),
      tool(
        "update_workspace",
        "Update metadata for the API key's current workspace. Do not use this to switch workspaces; MCP tools remain scoped to the authenticated API key workspace.",
        schema(%{
          name: string("Workspace display name."),
          cloud_profile: string("Optional cloud profile name or identifier."),
          cloud_profile_type: string("Optional cloud profile type."),
          url: string("Optional application URL."),
          max_threat_level: string("Optional deliberate threat level, such as td3 or td4.")
        }),
        {Workspace, :update_workspace},
        :update
      ),
      tool(
        "export_workspace",
        "Export the current workspace as Navigator JSON.",
        schema(%{}),
        {Workspace, :export_workspace},
        :read
      ),
      tool(
        "list_threats",
        "List threats in the current workspace.",
        schema(%{}),
        {ThreatModeling, :list_threats},
        :read
      ),
      tool(
        "create_threat",
        """
        Create a threat in the current workspace. Format fields for Navigator's threat statement renderer:
        "A/An [threat_source] [prerequisites] can [threat_action], which leads to [threat_impact], resulting in reduced [impacted_goal], negatively impacting [impacted_assets]."
        Do not include leading articles, "can", "which leads to", or trailing punctuation in the component fields.
        """,
        schema(threat_properties()),
        {ThreatModeling, :create_threat},
        :create
      ),
      tool(
        "update_threat",
        """
        Update a threat in the current workspace. Threat statement fields use the same grammar as create_threat:
        no leading article in threat_source, no "can" in threat_action, and no "which leads to" in threat_impact.
        """,
        schema(Map.put(threat_properties(), :id, id_property("Threat ID.")), ["id"]),
        {ThreatModeling, :update_threat},
        :update
      ),
      tool(
        "delete_threat",
        "Delete a threat in the current workspace.",
        schema(%{id: id_property("Threat ID.")}, ["id"]),
        {ThreatModeling, :delete_threat},
        :delete
      ),
      tool(
        "list_assumptions",
        "List assumptions in the current workspace.",
        schema(%{}),
        {ThreatModeling, :list_assumptions},
        :read
      ),
      tool(
        "create_assumption",
        "Create an assumption in the current workspace.",
        schema(assumption_properties()),
        {ThreatModeling, :create_assumption},
        :create
      ),
      tool(
        "update_assumption",
        "Update an assumption in the current workspace.",
        schema(Map.put(assumption_properties(), :id, id_property("Assumption ID.")), ["id"]),
        {ThreatModeling, :update_assumption},
        :update
      ),
      tool(
        "delete_assumption",
        "Delete an assumption in the current workspace.",
        schema(%{id: id_property("Assumption ID.")}, ["id"]),
        {ThreatModeling, :delete_assumption},
        :delete
      ),
      tool(
        "list_mitigations",
        "List mitigations in the current workspace.",
        schema(%{}),
        {ThreatModeling, :list_mitigations},
        :read
      ),
      tool(
        "create_mitigation",
        "Create a mitigation in the current workspace.",
        schema(mitigation_properties()),
        {ThreatModeling, :create_mitigation},
        :create
      ),
      tool(
        "update_mitigation",
        "Update a mitigation in the current workspace.",
        schema(Map.put(mitigation_properties(), :id, id_property("Mitigation ID.")), ["id"]),
        {ThreatModeling, :update_mitigation},
        :update
      ),
      tool(
        "delete_mitigation",
        "Delete a mitigation in the current workspace.",
        schema(%{id: id_property("Mitigation ID.")}, ["id"]),
        {ThreatModeling, :delete_mitigation},
        :delete
      ),
      tool(
        "link_entities",
        "Link two threat-modeling entities in the current workspace. Use this after creating related threats, assumptions, and mitigations.",
        schema(link_properties(), ["from_type", "from_id", "to_type", "to_id"]),
        {ThreatModeling, :link_entities},
        :create
      ),
      tool(
        "unlink_entities",
        "Unlink two threat-modeling entities in the current workspace.",
        schema(link_properties(), ["from_type", "from_id", "to_type", "to_id"]),
        {ThreatModeling, :unlink_entities},
        :delete
      ),
      tool(
        "get_application_information",
        "Get application information for the current workspace.",
        schema(%{}),
        {Documents, :get_application_information},
        :read
      ),
      tool(
        "update_application_information",
        "Update application information for the current workspace. Content may contain the same HTML-like rich text used by Navigator's editor.",
        schema(%{content: string("Application information rich-text content.")}, ["content"]),
        {Documents, :update_application_information},
        :update
      ),
      tool(
        "get_architecture",
        "Get architecture for the current workspace.",
        schema(%{}),
        {Documents, :get_architecture},
        :read
      ),
      tool(
        "update_architecture",
        "Update architecture for the current workspace. Content may contain the same HTML-like rich text used by Navigator's editor.",
        schema(%{content: string("Architecture rich-text content.")}, ["content"]),
        {Documents, :update_architecture},
        :update
      ),
      tool(
        "get_data_flow_diagram",
        "Get the data flow diagram for the current workspace.",
        schema(%{}),
        {Documents, :get_data_flow_diagram},
        :read
      ),
      tool(
        "update_data_flow_diagram",
        """
        Update the data flow diagram for the current workspace. Use only Navigator-supported node types:
        actor, process, datastore, and trust_boundary. Model external services as actor nodes unless they are internal processes or datastores.
        Include position.x and position.y for each node to control the rendered layout; omitted positions are auto-assigned and reported in validation_hints.
        To place a node inside a trust_boundary, set the child node's data.parent to the trust_boundary node ID.
        """,
        schema(%{
          nodes: dfd_nodes_schema(),
          edges: dfd_edges_schema(),
          raw_image: string("Optional raw image data associated with the DFD.")
        }),
        {Documents, :update_data_flow_diagram},
        :update
      ),
      tool(
        "export_dfd_mermaid",
        "Export the current workspace data flow diagram as Mermaid text.",
        schema(%{}),
        {Documents, :export_dfd_mermaid},
        :read
      )
    ]
  end

  defp tool(name, description, input_schema, handler, behavior) do
    %{
      name: name,
      description: String.trim(description),
      input_schema: input_schema,
      handler: handler,
      annotations: annotations(name, behavior)
    }
  end

  defp annotations(name, :read) do
    %{
      title: human_title(name),
      readOnlyHint: true,
      idempotentHint: true,
      openWorldHint: false
    }
  end

  defp annotations(name, :create) do
    %{
      title: human_title(name),
      readOnlyHint: false,
      destructiveHint: false,
      idempotentHint: false,
      openWorldHint: false
    }
  end

  defp annotations(name, :update) do
    %{
      title: human_title(name),
      readOnlyHint: false,
      destructiveHint: true,
      idempotentHint: true,
      openWorldHint: false
    }
  end

  defp annotations(name, :delete) do
    %{
      title: human_title(name),
      readOnlyHint: false,
      destructiveHint: true,
      idempotentHint: true,
      openWorldHint: false
    }
  end

  defp human_title(name) do
    name
    |> String.replace("_", " ")
    |> Phoenix.Naming.humanize()
  end

  defp threat_properties do
    %{
      threat_source:
        string("""
        Concise actor phrase only. Do not include a leading article such as "a", "an", or "the".
        Good: "external attacker with a leaked API key", "malicious workspace collaborator", "compromised CI runner".
        Bad: "An attacker with a leaked API key", "A malicious user.", "user credentials are weak".
        """),
      prerequisites:
        string("""
        Optional condition phrase that follows the actor. Do not include "can".
        Good: "who has obtained a valid workspace API key", "with write access to the workspace".
        Bad: "can access the workspace", "has obtained a token can".
        """),
      threat_action:
        string("""
        Concrete verb phrase describing what the actor does. No subject, no modal verbs, no leading "can", and no trailing punctuation.
        Good: "modify threat records through MCP", "submit malicious rich text", "reuse a stolen session cookie".
        Bad: "can modify threat records", "which leads to record tampering", "An attacker modifies records".
        """),
      threat_impact:
        string("""
        Direct impact phrase only. Do not include "which leads to" because Navigator adds it when rendering.
        Good: "unauthorized modification of threat model records", "exposure of workspace architecture details".
        Bad: "which leads to unauthorized modification", "causes exposure of data.".
        """),
      impacted_goal:
        string_array(
          "Security goals reduced by the threat, such as confidentiality, integrity, availability, accountability, or privacy."
        ),
      impacted_assets:
        string_array(
          "Concrete assets negatively impacted by the threat, such as workspace data, API keys, sessions, source code, or database records."
        ),
      comments:
        string("Optional analyst notes that are not part of the rendered threat statement."),
      stride: %{type: "array", items: %{type: "string", enum: @stride_values}},
      status: %{type: "string", enum: ["identified", "resolved", "not_useful"]},
      priority: %{type: "string", enum: ["low", "medium", "high"]},
      mitre_tactic: string("Optional MITRE tactic identifier or name."),
      kill_chain_phase: string("Optional kill chain phase."),
      threat_level: string("Optional deliberate threat level, such as td3 or td4."),
      tags: string_array("Free-form tags.")
    }
  end

  defp assumption_properties do
    %{
      content: string("Assumption statement."),
      comments: string("Optional analyst notes."),
      status: %{type: "string", enum: ["confirmed", "unconfirmed"]},
      tags: string_array("Free-form tags.")
    }
  end

  defp mitigation_properties do
    %{
      content: string("Mitigation statement."),
      comments: string("Optional analyst notes."),
      status: %{
        type: "string",
        enum: ["identified", "in_progress", "resolved", "will_not_action"]
      },
      tags: string_array("Free-form tags.")
    }
  end

  defp link_properties do
    %{
      from_type: %{type: "string", enum: ["threat", "assumption", "mitigation"]},
      from_id: id_property("Source entity ID."),
      to_type: %{type: "string", enum: ["threat", "assumption", "mitigation"]},
      to_id: id_property("Target entity ID.")
    }
  end

  defp dfd_nodes_schema do
    %{
      type: "object",
      description:
        "Map of node IDs to Cytoscape-style node objects. Each node must include data.id, data.label, and data.type.",
      additionalProperties: dfd_node_schema()
    }
  end

  defp dfd_node_schema do
    %{
      type: "object",
      properties: %{
        data: %{
          type: "object",
          properties: %{
            id: id_property("Node ID. Must match the key in the nodes map."),
            label: string("Human-readable node label."),
            type: %{
              type: "string",
              enum: @node_types,
              description:
                "Navigator-supported node type. Use actor for users, clients, and external systems; process for application services; datastore for persistent stores; trust_boundary only for grouping."
            },
            description: string("Optional node description."),
            parent:
              string(
                "Optional parent trust_boundary node ID. Set this on child nodes to render them inside a trust_boundary container."
              ),
            linked_threats: string_array("Threat IDs linked to this node."),
            data_tags: string_array("Data classification tags."),
            security_tags: string_array("Security feature tags."),
            technology_tags: string_array("Technology tags."),
            out_of_scope: string("Use \"false\" or \"true\".")
          },
          required: ["id", "label", "type"],
          additionalProperties: true
        },
        position: %{
          type: "object",
          description:
            "Rendered node coordinates. Strongly recommended; omitted or malformed positions are auto-assigned and returned in validation_hints.",
          properties: %{x: %{type: "number"}, y: %{type: "number"}},
          additionalProperties: true
        },
        grabbable: string("Use \"true\" or \"false\".")
      },
      required: ["data"],
      additionalProperties: true
    }
  end

  defp dfd_edges_schema do
    %{
      type: "object",
      description:
        "Map of edge IDs to Cytoscape-style edge objects. Each edge must include data.id, data.source, and data.target.",
      additionalProperties: %{
        type: "object",
        properties: %{
          data: %{
            type: "object",
            properties: %{
              id: id_property("Edge ID. Must match the key in the edges map."),
              source: id_property("Source node ID."),
              target: id_property("Target node ID."),
              label: string("Human-readable data flow label."),
              type: string("Use \"edge\"."),
              description: string("Optional edge description."),
              linked_threats: string_array("Threat IDs linked to this data flow."),
              data_tags: string_array("Data classification tags."),
              security_tags: string_array("Security feature tags."),
              technology_tags: string_array("Technology tags."),
              out_of_scope: string("Use \"false\" or \"true\".")
            },
            required: ["id", "source", "target"],
            additionalProperties: true
          }
        },
        required: ["data"],
        additionalProperties: true
      }
    }
  end

  defp id_property(description), do: string(description)

  defp string(description) do
    %{type: "string", description: String.trim(description)}
  end

  defp string_array(description) do
    %{type: "array", items: %{type: "string"}, description: String.trim(description)}
  end
end
