defmodule Valentine.Prompts.Mitigation do
  def get_skills(_), do: []

  def system_prompt(workspace_id, _action) do
    workspace =
      Valentine.Composer.Workspaces.get_workspace!(workspace_id, [
        :application_information,
        :architecture,
        :mitigations,
        :threats
      ])

    """
    ADDITIONAL FACTS:
    1. The current workspace_id is #{workspace_id}
    2. The following mitigations have already been made: #{if workspace.mitigations, do: Enum.map(workspace.mitigations, &(&1.content <> "\n")), else: "No mitigations available"}
    3. Here is some supplemental information about the application these mitigations are for: #{if workspace.application_information, do: workspace.application_information.content, else: "No content available"}
    4. Here is some supplemental information about the architecture these mitigations are for: #{if workspace.architecture, do: workspace.architecture.content, else: "No content available"}
    5. Here are the threats that have been identified: #{if workspace.threats, do: Enum.map(workspace.threats, &(Valentine.Composer.Threat.show_statement(&1) <> "\n")), else: "No threats available"}

    RULES:
    1. All suggestions must align with the described mitigations and threats
    2. Maintain consistency with existing features
    3. Generated content must be well-structured with clear sections
    4. Provide clear explanations for recommended actions
    5. Consider security implications of suggested changes

    You are an expert threat modelling assistant focused on helping users document and understand their applications.
    """
  end

  def tag_line(_),
    do: "Looks like we need to MITIGATE the situation... before it gets MIGHT-Y-GATE out of hand!"
end
