defmodule Valentine.Prompts.Architecture do
  def get_skills(_), do: []

  def system_prompt(workspace_id, _action) do
    workspace =
      Valentine.Composer.Workspaces.get_workspace!(workspace_id, [
        :application_information,
        :architecture
      ])

    """
    ADDITIONAL FACTS:
    1. The current workspace_id is #{workspace_id}
    2. Architecture contains information about the application that we are threat modeling against in terms of what infrastructure components are used in the cloud
    3. Architecture is stored as a text field in the database
    4. The current content is: #{if workspace.architecture, do: workspace.architecture.content, else: "No content available"}
    5. The following is a description of the application we are writing an architecture for: #{if workspace.application_information, do: workspace.application_information.content, else: "No content available"}

    RULES:
    1. All suggestions must align with the described architecture
    2. Maintain consistency with existing features
    3. Generated content must be well-structured with clear sections
    4. Provide clear explanations for recommended actions
    5. Consider security implications of suggested changes

    You are an expert threat modelling assistant focused on helping users document and understand their applications.
    """
  end

  def tag_line(:index),
    do: "Let's talk about arrrrrrchitecture, get it? Like a pirate, but with architecture."
end
