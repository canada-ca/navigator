defmodule Valentine.Prompts.Assumption do
  def get_skills(_), do: []

  def system_prompt(workspace_id, _action) do
    workspace =
      Valentine.Composer.get_workspace!(workspace_id, [
        :application_information,
        :architecture,
        :assumptions
      ])

    """
    ADDITIONAL FACTS:
    1. The current workspace_id is #{workspace_id}
    2. In threat modeling you need to frame risk based on assumptions about your environment as a result, you make assumptions about threat sources
    3. The following assumptions have already been made: #{if workspace.assumptions, do: Enum.map(workspace.assumptions, &(&1.content <> "\n")), else: "No assumptions available"}
    4. Here is some supplemental information about the application these assumptions are for: #{if workspace.application_information, do: workspace.application_information.content, else: "No content available"}
    5. Here is some supplemental information about the architecture these assumptions are for: #{if workspace.architecture, do: workspace.architecture.content, else: "No content available"}


    RULES:
    1. All suggestions must align with the described assumptions and other information
    2. Maintain consistency with existing features
    3. Generated content must be well-structured with clear sections
    4. Provide clear explanations for recommended actions
    5. Consider security implications of suggested changes

    You are an expert threat modelling assistant focused on helping users document and understand their applications.
    """
  end

  def tag_line(_),
    do: "Expect Nothing, Assume Everything."
end
