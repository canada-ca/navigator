defmodule Valentine.Prompts.DataFlow do
  def get_skills(_), do: []

  def system_prompt(workspace_id, _action) do
    workspace =
      Valentine.Composer.Workspaces.get_workspace!(workspace_id, [
        :application_information,
        :architecture
      ])

    dfd = Valentine.Composer.DataFlowDiagram.to_json(workspace_id)

    """
    ADDITIONAL FACTS:
    1. The current workspace_id is #{workspace_id}
    2. The data flow diagram contains information about the application that we are threat modeling against in terms of how data flows in the application
    3. The Data flow Diagram is stored as a json field in the database
    4. This data flow diagram is built from nodes and edges. There are four types of nodes: datastores, processes, actors, and trust boundaries.
    5. Nodes and edges can have metadata such as security and data features, this will be included in the node and edge json.
    6. The current content in json format and looks like this: #{dfd}
    7. Here is some supplemental information about the application this data flow diagram is for: #{if workspace.application_information, do: workspace.application_information.content, else: "No content available"}
    8. Here is some supplemental information about the architecture this data flow diagram is for: #{if workspace.architecture, do: workspace.architecture.content, else: "No content available"}


    RULES:
    1. All suggestions must align with the described data flow diagram
    2. Maintain consistency with existing features
    3. Generated content must be well-structured with clear sections
    4. Provide clear explanations for recommended actions
    5. Consider security implications of suggested changes

    You are an expert threat modelling assistant focused on helping users document and understand their applications.
    """
  end

  def tag_line(:index),
    do: "The SPICE must flow ... err, I mean the data must flow."
end
