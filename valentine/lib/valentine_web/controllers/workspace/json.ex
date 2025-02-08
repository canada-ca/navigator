defmodule ValentineWeb.Workspace.Json do
  def serialize_workspace(workspace) do
    %{
      workspace: %{
        name: workspace.name,
        application_information: %{
          content: get_in(workspace.application_information.content)
        },
        architecture: %{
          content: get_in(workspace.architecture.content)
        },
        data_flow_diagram: %{
          edges: get_in(workspace.data_flow_diagram.edges),
          nodes: get_in(workspace.data_flow_diagram.nodes)
        },
        assumptions: serialize_assumptions(workspace.assumptions),
        mitigations: serialize_mitigations(workspace.mitigations),
        threats: serialize_threats(workspace.threats)
      }
    }
    |> Jason.encode!()
  end

  def serialize_assumptions(assumptions) do
    Enum.map(assumptions, fn assumption ->
      %{
        id: assumption.id,
        content: assumption.content,
        comments: assumption.comments,
        tags: assumption.tags,
        threats: Enum.map(assumption.threats, & &1.id),
        mitigations: Enum.map(assumption.mitigations, & &1.id)
      }
    end)
  end

  def serialize_mitigations(mitigations) do
    Enum.map(mitigations, fn mitigation ->
      %{
        id: mitigation.id,
        content: mitigation.content,
        comments: mitigation.comments,
        status: mitigation.status,
        tags: mitigation.tags,
        threats: Enum.map(mitigation.threats, & &1.id),
        assumptions: Enum.map(mitigation.assumptions, & &1.id)
      }
    end)
  end

  def serialize_threats(threats) do
    Enum.map(threats, fn threat ->
      %{
        id: threat.id,
        status: threat.status,
        priority: threat.priority,
        stride: threat.stride,
        comments: threat.comments,
        threat_source: threat.threat_source,
        prerequisites: threat.prerequisites,
        threat_action: threat.threat_action,
        threat_impact: threat.threat_impact,
        impacted_goal: threat.impacted_goal,
        impacted_assets: threat.impacted_assets,
        tags: threat.tags,
        assumptions: Enum.map(threat.assumptions, & &1.id),
        mitigations: Enum.map(threat.mitigations, & &1.id)
      }
    end)
  end
end
