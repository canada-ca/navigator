defmodule ValentineWeb.WorkspaceLive.ThreatModel.ReportComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ValentineWeb.WorkspaceLive.ThreatModel.Components.MarkdownReportComponent
  alias ValentineWeb.WorkspaceLive.ThreatModel.Components.ReportComponent

  test "renders tags and threat agents in the report outputs" do
    workspace = %{
      application_information: nil,
      architecture: nil,
      data_flow_diagram: nil,
      assumptions: [
        %{
          numeric_id: 3,
          content: "Administrators use managed devices.",
          comments: nil,
          tags: ["governance", "AC-2"],
          threats: [],
          mitigations: []
        }
      ],
      threat_agents: [
        %{
          name: "Organized criminal group",
          agent_class: "External",
          capability: "High",
          motivation: "Financial gain",
          td_level: :td4
        }
      ],
      threats: [
        %{
          id: "threat-1",
          numeric_id: 1,
          status: :identified,
          priority: :high,
          stride: [:spoofing],
          comments: "AC-1, SC-7",
          threat_source: "attacker",
          prerequisites: "with stolen credentials",
          threat_action: "access the admin panel",
          threat_impact: "service disruption",
          impacted_goal: ["availability"],
          impacted_assets: ["Admin Panel"],
          tags: ["AC-1", "SC-7"],
          assumptions: [],
          mitigations: [
            %{numeric_id: 2}
          ]
        }
      ],
      mitigations: [
        %{
          numeric_id: 2,
          content: "Enforce MFA for all privileged accounts.",
          comments: nil,
          tags: ["IA-2", "AC-7"],
          assumptions: [],
          threats: [
            %{numeric_id: 1}
          ]
        }
      ]
    }

    html = render_component(&ReportComponent.render/1, workspace: workspace)

    assert html =~ "Tags"
    assert html =~ "Threat Agents"
    assert html =~ "Administrators use managed devices."
    assert html =~ "governance"
    assert html =~ "AC-1"
    assert html =~ "SC-7"
    assert html =~ "IA-2"
    assert html =~ "AC-7"
    assert html =~ "Organized criminal group"
    assert html =~ "Td4 - Organized Criminal Group"
    refute html =~ "AC-1, SC-7</td>"

    markdown =
      MarkdownReportComponent.generate_markdown(workspace, %{"threat-1" => hd(workspace.threats)})

    assert markdown =~
             "| Assumption ID | Assumption | Linked Threats | Linked Mitigations | Tags | Comments |"

    assert markdown =~
             "| <a name=\"a-3\"></a>A-3 | Administrators use managed devices. |  |  | governance, AC-2 |  |"

    assert markdown =~
             "## <a name=\"threat-agents\"></a>5. Threat Agents"

    assert markdown =~
             "| Name | Class | Capability | Motivation | Threat Level |"

    assert markdown =~
             "| Organized criminal group | External | High | Financial gain | Td4 - Organized Criminal Group |"

    assert markdown =~
             "| Threat ID | Threat | Assumptions | Mitigations | Status | Priority | STRIDE | Tags | Comments |"

    assert markdown =~
             "| <a name=\"t-1\"></a>T-1 | An attacker with stolen credentials can access the admin panel, which leads to service disruption, resulting in reduced availability negatively impacting Admin Panel. |  | [M-2](#m-2) | Identified | High | S | AC-1, SC-7 |  |"

    assert markdown =~
             "| <a name=\"m-2\"></a>M-2 | Enforce MFA for all privileged accounts. | [T-1](#t-1) |  | IA-2, AC-7 |  |"
  end
end
