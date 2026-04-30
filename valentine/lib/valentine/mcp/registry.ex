defmodule Valentine.MCP.Registry do
  import Valentine.MCP.ToolHelpers, only: [schema: 1, schema: 2]

  alias Valentine.MCP.Tools.Documents
  alias Valentine.MCP.Tools.ThreatModeling
  alias Valentine.MCP.Tools.Workspace

  @string %{type: "string"}
  @string_array %{type: "array", items: @string}
  @stride_values [
    "spoofing",
    "tampering",
    "repudiation",
    "information_disclosure",
    "denial_of_service",
    "elevation_of_privilege"
  ]

  @tool_specs [
    {"list_workspaces", "List workspaces accessible to the API key owner.", schema(%{}),
     {Workspace, :list_workspaces}},
    {"get_workspace", "Get the API key's current workspace.", schema(%{}),
     {Workspace, :get_workspace}},
    {"update_workspace", "Update the API key's current workspace.",
     schema(%{
       name: @string,
       cloud_profile: @string,
       cloud_profile_type: @string,
       url: @string,
       max_threat_level: @string,
       permissions: %{type: "object"}
     }), {Workspace, :update_workspace}},
    {"export_workspace", "Export the current workspace as Navigator JSON.", schema(%{}),
     {Workspace, :export_workspace}},
    {"list_threats", "List threats in the current workspace.", schema(%{}),
     {ThreatModeling, :list_threats}},
    {"create_threat", "Create a threat in the current workspace.",
     schema(%{
       threat_source: @string,
       prerequisites: @string,
       threat_action: @string,
       threat_impact: @string,
       impacted_goal: @string_array,
       impacted_assets: @string_array,
       comments: @string,
       stride: %{type: "array", items: %{type: "string", enum: @stride_values}},
       status: %{type: "string", enum: ["identified", "resolved", "not_useful"]},
       priority: %{type: "string", enum: ["low", "medium", "high"]},
       mitre_tactic: @string,
       kill_chain_phase: @string,
       threat_level: @string,
       tags: @string_array
     }), {ThreatModeling, :create_threat}},
    {"update_threat", "Update a threat in the current workspace.",
     schema(
       %{
         id: @string,
         threat_source: @string,
         prerequisites: @string,
         threat_action: @string,
         threat_impact: @string,
         impacted_goal: @string_array,
         impacted_assets: @string_array,
         comments: @string,
         stride: %{type: "array", items: %{type: "string", enum: @stride_values}},
         status: %{type: "string", enum: ["identified", "resolved", "not_useful"]},
         priority: %{type: "string", enum: ["low", "medium", "high"]},
         mitre_tactic: @string,
         kill_chain_phase: @string,
         threat_level: @string,
         tags: @string_array
       },
       ["id"]
     ), {ThreatModeling, :update_threat}},
    {"delete_threat", "Delete a threat in the current workspace.", schema(%{id: @string}, ["id"]),
     {ThreatModeling, :delete_threat}},
    {"list_assumptions", "List assumptions in the current workspace.", schema(%{}),
     {ThreatModeling, :list_assumptions}},
    {"create_assumption", "Create an assumption in the current workspace.",
     schema(%{
       content: @string,
       comments: @string,
       status: %{type: "string", enum: ["confirmed", "unconfirmed"]},
       tags: @string_array
     }), {ThreatModeling, :create_assumption}},
    {"update_assumption", "Update an assumption in the current workspace.",
     schema(
       %{
         id: @string,
         content: @string,
         comments: @string,
         status: %{type: "string", enum: ["confirmed", "unconfirmed"]},
         tags: @string_array
       },
       ["id"]
     ), {ThreatModeling, :update_assumption}},
    {"delete_assumption", "Delete an assumption in the current workspace.",
     schema(%{id: @string}, ["id"]), {ThreatModeling, :delete_assumption}},
    {"list_mitigations", "List mitigations in the current workspace.", schema(%{}),
     {ThreatModeling, :list_mitigations}},
    {"create_mitigation", "Create a mitigation in the current workspace.",
     schema(%{
       content: @string,
       comments: @string,
       status: %{
         type: "string",
         enum: ["identified", "in_progress", "resolved", "will_not_action"]
       },
       tags: @string_array
     }), {ThreatModeling, :create_mitigation}},
    {"update_mitigation", "Update a mitigation in the current workspace.",
     schema(
       %{
         id: @string,
         content: @string,
         comments: @string,
         status: %{
           type: "string",
           enum: ["identified", "in_progress", "resolved", "will_not_action"]
         },
         tags: @string_array
       },
       ["id"]
     ), {ThreatModeling, :update_mitigation}},
    {"delete_mitigation", "Delete a mitigation in the current workspace.",
     schema(%{id: @string}, ["id"]), {ThreatModeling, :delete_mitigation}},
    {"link_entities", "Link two threat-modeling entities in the current workspace.",
     schema(
       %{
         from_type: %{type: "string", enum: ["threat", "assumption", "mitigation"]},
         from_id: @string,
         to_type: %{type: "string", enum: ["threat", "assumption", "mitigation"]},
         to_id: @string
       },
       ["from_type", "from_id", "to_type", "to_id"]
     ), {ThreatModeling, :link_entities}},
    {"unlink_entities", "Unlink two threat-modeling entities in the current workspace.",
     schema(
       %{
         from_type: %{type: "string", enum: ["threat", "assumption", "mitigation"]},
         from_id: @string,
         to_type: %{type: "string", enum: ["threat", "assumption", "mitigation"]},
         to_id: @string
       },
       ["from_type", "from_id", "to_type", "to_id"]
     ), {ThreatModeling, :unlink_entities}},
    {"get_application_information", "Get application information for the current workspace.",
     schema(%{}), {Documents, :get_application_information}},
    {"update_application_information",
     "Update application information for the current workspace.",
     schema(%{content: @string}, ["content"]), {Documents, :update_application_information}},
    {"get_architecture", "Get architecture for the current workspace.", schema(%{}),
     {Documents, :get_architecture}},
    {"update_architecture", "Update architecture for the current workspace.",
     schema(%{content: @string}, ["content"]), {Documents, :update_architecture}},
    {"get_data_flow_diagram", "Get the data flow diagram for the current workspace.", schema(%{}),
     {Documents, :get_data_flow_diagram}},
    {"update_data_flow_diagram", "Update the data flow diagram for the current workspace.",
     schema(%{nodes: %{type: "object"}, edges: %{type: "object"}, raw_image: @string}),
     {Documents, :update_data_flow_diagram}},
    {"export_dfd_mermaid", "Export the current workspace data flow diagram as Mermaid text.",
     schema(%{}), {Documents, :export_dfd_mermaid}}
  ]

  @tool_definitions Enum.map(@tool_specs, fn {name, description, input_schema, _handler} ->
                      %{name: name, description: description, inputSchema: input_schema}
                    end)
  @tool_handlers Map.new(@tool_specs, fn {name, _description, _schema, handler} ->
                   {name, handler}
                 end)

  def tool_definitions, do: @tool_definitions

  def call_tool(name, args, api_key) do
    case Map.fetch(@tool_handlers, name) do
      {:ok, {module, function}} ->
        case apply(module, function, [args, api_key]) do
          {:ok, content} ->
            {:ok, %{content: content, isError: false}}

          {:tool_error, message} ->
            {:ok, %{content: [%{type: "text", text: message}], isError: true}}
        end

      :error ->
        {:error, -32602, "Unknown tool: #{name}"}
    end
  rescue
    error in Ecto.NoResultsError ->
      {:ok, %{content: [%{type: "text", text: Exception.message(error)}], isError: true}}

    error in Ecto.InvalidChangesetError ->
      {:ok, %{content: [%{type: "text", text: Exception.message(error)}], isError: true}}
  end
end
