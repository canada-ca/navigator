defmodule Valentine.ThreatModelQualityReview.Snapshot do
  @moduledoc false

  alias Valentine.Composer
  alias Valentine.Composer.DataFlowDiagram

  def build(workspace_id) do
    workspace =
      Composer.get_workspace!(workspace_id, [
        :application_information,
        :architecture,
        threats: [:assumptions, :mitigations, :evidence],
        assumptions: [:threats, :mitigations, :evidence],
        mitigations: [:threats, :assumptions, :evidence],
        evidence: [:threats, :assumptions, :mitigations]
      ])

    dfd = DataFlowDiagram.get(workspace_id, false)

    %{
      workspace: %{
        id: workspace.id,
        name: workspace.name,
        cloud_profile: workspace.cloud_profile,
        cloud_profile_type: workspace.cloud_profile_type,
        url: workspace.url,
        max_threat_level: workspace.max_threat_level
      },
      application_information:
        if(workspace.application_information, do: workspace.application_information.content),
      architecture: if(workspace.architecture, do: workspace.architecture.content),
      dfd: %{
        nodes: dfd.nodes |> Map.values() |> Enum.sort_by(&get_in(&1, ["data", "id"])),
        edges: dfd.edges |> Map.values() |> Enum.sort_by(&get_in(&1, ["data", "id"]))
      },
      threats: Enum.map(workspace.threats, &threat_payload/1),
      assumptions: Enum.map(workspace.assumptions, &assumption_payload/1),
      mitigations: Enum.map(workspace.mitigations, &mitigation_payload/1),
      evidence: Enum.map(workspace.evidence, &evidence_payload/1)
    }
  end

  defp threat_payload(threat) do
    %{
      id: threat.id,
      numeric_id: threat.numeric_id,
      status: threat.status,
      priority: threat.priority,
      stride: threat.stride || [],
      threat_level: threat.threat_level,
      mitre_tactic: threat.mitre_tactic,
      kill_chain_phase: threat.kill_chain_phase,
      threat_source: threat.threat_source,
      prerequisites: threat.prerequisites,
      threat_action: threat.threat_action,
      threat_impact: threat.threat_impact,
      impacted_goal: threat.impacted_goal || [],
      impacted_assets: threat.impacted_assets || [],
      tags: threat.tags || [],
      assumption_ids: Enum.map(threat.assumptions, & &1.id),
      mitigation_ids: Enum.map(threat.mitigations, & &1.id),
      evidence_ids: Enum.map(threat.evidence, & &1.id)
    }
  end

  defp assumption_payload(assumption) do
    %{
      id: assumption.id,
      numeric_id: assumption.numeric_id,
      content: assumption.content,
      status: assumption.status,
      tags: assumption.tags || [],
      threat_ids: Enum.map(assumption.threats, & &1.id),
      mitigation_ids: Enum.map(assumption.mitigations, & &1.id),
      evidence_ids: Enum.map(assumption.evidence, & &1.id)
    }
  end

  defp mitigation_payload(mitigation) do
    %{
      id: mitigation.id,
      numeric_id: mitigation.numeric_id,
      content: mitigation.content,
      status: mitigation.status,
      tags: mitigation.tags || [],
      threat_ids: Enum.map(mitigation.threats, & &1.id),
      assumption_ids: Enum.map(mitigation.assumptions, & &1.id),
      evidence_ids: Enum.map(mitigation.evidence, & &1.id)
    }
  end

  defp evidence_payload(evidence) do
    %{
      id: evidence.id,
      numeric_id: evidence.numeric_id,
      name: evidence.name,
      description: evidence.description,
      evidence_type: evidence.evidence_type,
      nist_controls: evidence.nist_controls || [],
      tags: evidence.tags || [],
      threat_ids: Enum.map(evidence.threats, & &1.id),
      assumption_ids: Enum.map(evidence.assumptions, & &1.id),
      mitigation_ids: Enum.map(evidence.mitigations, & &1.id)
    }
  end
end
