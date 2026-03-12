defmodule Valentine.RepoAnalysis.PersisterTest do
  use Valentine.DataCase

  alias Valentine.Composer
  alias Valentine.RepoAnalysis.Generator.Analysis
  alias Valentine.RepoAnalysis.Persister

  import Valentine.ComposerFixtures

  @generated_tags ["AI generated", "GitHub import"]

  describe "persist/2" do
    test "persists generated artifacts and threat links" do
      workspace = workspace_fixture()

      analysis =
        analysis_fixture(%{
          application_information: "Generated application information",
          architecture: "Generated architecture",
          assumptions: [
            %{
              "content" => "The API is only reachable through the load balancer",
              "related_threat_indexes" => [0]
            }
          ],
          mitigations: [
            %{"content" => "Enforce MFA for administrators", "related_threat_indexes" => [0, 1]}
          ],
          threats: [
            threat_json("admin", ["api"]),
            threat_json("attacker", ["worker"])
          ],
          dfd: dfd_json()
        })

      assert :ok = Persister.persist(workspace.id, analysis)

      workspace = Composer.get_workspace!(workspace.id, [:application_information, :architecture])
      assert workspace.application_information.content == "Generated application information"
      assert workspace.architecture.content == "Generated architecture"

      generated_threats = generated_threats(workspace.id)
      assert length(generated_threats) == 2

      [first_threat, second_threat] = Enum.sort_by(generated_threats, & &1.numeric_id)

      [assumption] = generated_assumptions(workspace.id)
      assumption = Composer.get_assumption!(assumption.id, [:threats])
      assert Enum.map(assumption.threats, & &1.id) == [first_threat.id]

      [mitigation] = generated_mitigations(workspace.id)
      mitigation = Composer.get_mitigation!(mitigation.id, [:threats])

      assert Enum.sort(Enum.map(mitigation.threats, & &1.id)) ==
               Enum.sort([first_threat.id, second_threat.id])

      data_flow_diagram = Composer.get_data_flow_diagram_by_workspace_id(workspace.id)

      assert get_in(data_flow_diagram.nodes, ["api", "data", "linked_threats"]) == [
               first_threat.id
             ]

      assert get_in(data_flow_diagram.nodes, ["user", "data", "type"]) == "actor"
      assert get_in(data_flow_diagram.nodes, ["db", "data", "type"]) == "datastore"

      assert get_in(data_flow_diagram.nodes, ["worker", "data", "linked_threats"]) == [
               second_threat.id
             ]

      assert get_in(data_flow_diagram.nodes, ["internet", "position", "x"]) != 50
      assert get_in(data_flow_diagram.nodes, ["api", "position", "x"]) != 50
      assert get_in(data_flow_diagram.nodes, ["db", "position", "x"]) != 50

      assert data_flow_diagram.nodes["api"]["position"] !=
               data_flow_diagram.nodes["db"]["position"]
    end

    test "rerunning with the same analysis preserves generated records and manual links" do
      workspace = workspace_fixture()

      {:ok, manual_threat} =
        Composer.create_threat(%{
          workspace_id: workspace.id,
          threat_source: "manual actor",
          prerequisites: "already has access",
          threat_action: "change configuration",
          threat_impact: "weakens controls",
          impacted_goal: ["integrity"],
          impacted_assets: ["admin console"],
          stride: [:tampering],
          tags: ["manual"]
        })

      analysis =
        analysis_fixture(%{
          assumptions: [
            %{"content" => "Only admins can reach the dashboard", "related_threat_indexes" => [0]}
          ],
          mitigations: [
            %{"content" => "Audit privileged changes", "related_threat_indexes" => [0]}
          ],
          threats: [threat_json("external actor", ["api"])],
          dfd: dfd_json()
        })

      assert :ok = Persister.persist(workspace.id, analysis)

      [generated_threat] = generated_threats(workspace.id)
      [generated_assumption] = generated_assumptions(workspace.id)
      [generated_mitigation] = generated_mitigations(workspace.id)

      assert {:ok, _assumption} =
               Composer.add_threat_to_assumption(generated_assumption, manual_threat)

      assert {:ok, _threat} =
               Composer.add_mitigation_to_threat(manual_threat, generated_mitigation)

      assert :ok = Persister.persist(workspace.id, analysis)

      [rerun_generated_threat] = generated_threats(workspace.id)
      [rerun_generated_assumption] = generated_assumptions(workspace.id)
      [rerun_generated_mitigation] = generated_mitigations(workspace.id)

      assert rerun_generated_threat.id == generated_threat.id
      assert rerun_generated_assumption.id == generated_assumption.id
      assert rerun_generated_mitigation.id == generated_mitigation.id

      rerun_generated_assumption =
        Composer.get_assumption!(rerun_generated_assumption.id, [:threats])

      rerun_generated_mitigation =
        Composer.get_mitigation!(rerun_generated_mitigation.id, [:threats])

      assert Enum.sort(Enum.map(rerun_generated_assumption.threats, & &1.id)) ==
               Enum.sort([manual_threat.id, rerun_generated_threat.id])

      assert Enum.sort(Enum.map(rerun_generated_mitigation.threats, & &1.id)) ==
               Enum.sort([manual_threat.id, rerun_generated_threat.id])

      assert length(generated_threats(workspace.id)) == 1
      assert length(Composer.list_threats_by_workspace(workspace.id)) == 2
    end

    test "removes stale generated records on rerun" do
      workspace = workspace_fixture()

      initial_analysis =
        analysis_fixture(%{
          assumptions: [
            %{"content" => "Initial assumption", "related_threat_indexes" => [0]}
          ],
          mitigations: [
            %{"content" => "Initial mitigation", "related_threat_indexes" => [0]}
          ],
          threats: [threat_json("initial actor", ["api"])],
          dfd: dfd_json()
        })

      assert :ok = Persister.persist(workspace.id, initial_analysis)
      assert length(generated_threats(workspace.id)) == 1
      assert length(generated_assumptions(workspace.id)) == 1
      assert length(generated_mitigations(workspace.id)) == 1

      updated_analysis =
        analysis_fixture(%{
          application_information: "Updated application information",
          architecture: "Updated architecture",
          assumptions: [],
          mitigations: [],
          threats: [],
          dfd: %{"boundaries" => [], "components" => [], "flows" => []}
        })

      assert :ok = Persister.persist(workspace.id, updated_analysis)
      assert generated_threats(workspace.id) == []
      assert generated_assumptions(workspace.id) == []
      assert generated_mitigations(workspace.id) == []

      workspace = Composer.get_workspace!(workspace.id, [:application_information, :architecture])
      assert workspace.application_information.content == "Updated application information"
      assert workspace.architecture.content == "Updated architecture"
    end

    test "lays out actors, processes, and datastores in distinct lanes" do
      workspace = workspace_fixture()

      analysis =
        analysis_fixture(%{
          dfd: lane_dfd_json()
        })

      assert :ok = Persister.persist(workspace.id, analysis)

      data_flow_diagram = Composer.get_data_flow_diagram_by_workspace_id(workspace.id)

      browser_y = get_in(data_flow_diagram.nodes, ["browser", "position", "y"])
      admin_y = get_in(data_flow_diagram.nodes, ["admin", "position", "y"])
      api_y = get_in(data_flow_diagram.nodes, ["api", "position", "y"])
      worker_y = get_in(data_flow_diagram.nodes, ["worker", "position", "y"])
      db_y = get_in(data_flow_diagram.nodes, ["db", "position", "y"])

      assert browser_y < api_y
      assert admin_y < api_y
      assert api_y < db_y
      assert worker_y < db_y
      assert browser_y != admin_y

      assert get_in(data_flow_diagram.nodes, ["browser", "position", "x"]) <
               get_in(data_flow_diagram.nodes, ["api", "position", "x"])

      assert get_in(data_flow_diagram.nodes, ["api", "position", "x"]) <
               get_in(data_flow_diagram.nodes, ["db", "position", "x"])
    end
  end

  defp analysis_fixture(attrs) do
    struct!(
      Analysis,
      Map.merge(
        %{
          application_information: "Application information",
          architecture: "Architecture",
          assumptions: [],
          mitigations: [],
          threats: [],
          dfd: %{"boundaries" => [], "components" => [], "flows" => []}
        },
        attrs
      )
    )
  end

  defp dfd_json do
    %{
      "boundaries" => [
        %{"id" => "internet", "label" => "Internet", "description" => "Public network"}
      ],
      "components" => [
        %{
          "id" => "user",
          "label" => "User",
          "kind" => "external_entity",
          "description" => "Human actor",
          "boundary_id" => nil
        },
        %{
          "id" => "api",
          "label" => "API",
          "kind" => "process",
          "description" => "Public API",
          "boundary_id" => "internet"
        },
        %{
          "id" => "db",
          "label" => "Primary DB",
          "kind" => "data_store",
          "description" => "System of record",
          "boundary_id" => "internet"
        },
        %{
          "id" => "worker",
          "label" => "Worker",
          "kind" => "process",
          "description" => "Background worker",
          "boundary_id" => nil
        }
      ],
      "flows" => [
        %{
          "source" => "user",
          "target" => "api",
          "label" => "User inputs secret",
          "description" => "Submits secret data"
        },
        %{
          "source" => "api",
          "target" => "db",
          "label" => "Store",
          "description" => "Writes state"
        },
        %{
          "source" => "api",
          "target" => "worker",
          "label" => "Dispatch",
          "description" => "Enqueues work"
        }
      ]
    }
  end

  defp lane_dfd_json do
    %{
      "boundaries" => [
        %{"id" => "platform", "label" => "Platform", "description" => "Primary system"}
      ],
      "components" => [
        %{
          "id" => "browser",
          "label" => "Browser",
          "kind" => "external_entity",
          "description" => "End user browser",
          "boundary_id" => "platform"
        },
        %{
          "id" => "admin",
          "label" => "Admin",
          "kind" => "external_entity",
          "description" => "Operator",
          "boundary_id" => "platform"
        },
        %{
          "id" => "api",
          "label" => "API",
          "kind" => "process",
          "description" => "Entry point",
          "boundary_id" => "platform"
        },
        %{
          "id" => "worker",
          "label" => "Worker",
          "kind" => "process",
          "description" => "Background processor",
          "boundary_id" => "platform"
        },
        %{
          "id" => "db",
          "label" => "Database",
          "kind" => "data_store",
          "description" => "Persistent store",
          "boundary_id" => "platform"
        }
      ],
      "flows" => [
        %{
          "source" => "browser",
          "target" => "api",
          "label" => "Request",
          "description" => "User request"
        },
        %{
          "source" => "admin",
          "target" => "api",
          "label" => "Admin request",
          "description" => "Administrative request"
        },
        %{
          "source" => "api",
          "target" => "worker",
          "label" => "Dispatch",
          "description" => "Enqueue work"
        },
        %{
          "source" => "worker",
          "target" => "db",
          "label" => "Persist",
          "description" => "Write records"
        }
      ]
    }
  end

  defp generated_assumptions(workspace_id) do
    workspace_id
    |> Composer.list_assumptions_by_workspace()
    |> Enum.filter(&generated_record?/1)
  end

  defp generated_mitigations(workspace_id) do
    workspace_id
    |> Composer.list_mitigations_by_workspace()
    |> Enum.filter(&generated_record?/1)
  end

  defp generated_threats(workspace_id) do
    workspace_id
    |> Composer.list_threats_by_workspace()
    |> Enum.filter(&generated_record?/1)
  end

  defp generated_record?(record) do
    Enum.all?(@generated_tags, &(&1 in (record.tags || [])))
  end

  defp threat_json(source, related_component_ids) do
    %{
      "threat_source" => source,
      "prerequisites" => "has network reachability",
      "threat_action" => "send crafted input",
      "threat_impact" => "cause data exposure",
      "impacted_goal" => ["confidentiality"],
      "impacted_assets" => ["customer records"],
      "stride" => ["information_disclosure"],
      "related_component_ids" => related_component_ids
    }
  end
end
