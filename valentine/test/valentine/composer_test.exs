defmodule Valentine.ComposerTest do
  use Valentine.DataCase

  alias Valentine.Composer

  describe "workspaces" do
    alias Valentine.Composer.Workspace

    import Valentine.ComposerFixtures

    @invalid_attrs %{name: nil}

    test "list_workspaces/0 returns all workspaces" do
      workspace = workspace_fixture()
      assert Composer.list_workspaces() == [workspace]
    end

    test "list_workspaces_by_identity/1 returns all workspaces for a owner" do
      workspace = workspace_fixture()
      workspace_fixture(%{owner: "another owner"})
      assert Composer.list_workspaces_by_identity(workspace.owner) == [workspace]
    end

    test "list_workspaces_by_identity/1 returns all workspaces for a collaborator" do
      workspace =
        workspace_fixture(%{owner: "another owner", permissions: %{"collaborator" => "read"}})

      workspace_fixture(%{owner: "another owner"})
      assert Composer.list_workspaces_by_identity("collaborator") == [workspace]
    end

    test "get_workspace!/1 returns the workspace with given id" do
      workspace = workspace_fixture()
      assert Composer.get_workspace!(workspace.id) == workspace
    end

    test "create_workspace/1 with valid data creates a workspace" do
      valid_attrs = %{
        name: "some name",
        cloud_profile: "some cloud_profile",
        cloud_profile_type: "some cloud_profile_type",
        url: "some url",
        owner: "some owner",
        permissions: %{}
      }

      assert {:ok, %Workspace{} = workspace} = Composer.create_workspace(valid_attrs)
      assert workspace.name == "some name"
      assert workspace.cloud_profile == "some cloud_profile"
      assert workspace.cloud_profile_type == "some cloud_profile_type"
      assert workspace.url == "some url"
      assert workspace.owner == "some owner"
      assert workspace.permissions == %{}
    end

    test "create_workspace/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_workspace(@invalid_attrs)
    end

    test "update_workspace/2 with valid data updates the workspace" do
      workspace = workspace_fixture()

      update_attrs = %{
        name: "some updated name",
        cloud_profile: "some updated cloud_profile",
        cloud_profile_type: "some updated cloud_profile_type",
        url: "some updated url",
        owner: "some updated owner",
        permissions: %{some: "permissions"}
      }

      assert {:ok, %Workspace{} = workspace} = Composer.update_workspace(workspace, update_attrs)
      assert workspace.name == "some updated name"
      assert workspace.cloud_profile == "some updated cloud_profile"
      assert workspace.cloud_profile_type == "some updated cloud_profile_type"
      assert workspace.url == "some updated url"
      assert workspace.owner == "some updated owner"
      assert workspace.permissions == %{some: "permissions"}
    end

    test "update_workspace/2 with invalid data returns error changeset" do
      workspace = workspace_fixture()
      assert {:error, %Ecto.Changeset{}} = Composer.update_workspace(workspace, @invalid_attrs)
      assert workspace == Composer.get_workspace!(workspace.id)
    end

    test "update_workspace_permissions/2 with none permission removes an identity and updates the workspace permissions" do
      workspace =
        workspace_fixture(%{
          permissions: %{"identity" => "permission", "another" => "permission"}
        })

      assert {:ok, %Workspace{} = workspace} =
               Composer.update_workspace_permissions(workspace, "identity", "none")

      assert workspace.permissions == %{"another" => "permission"}
    end

    test "update_workspace_permissions/2 with valid data updates the workspace permissions" do
      workspace = workspace_fixture()

      assert {:ok, %Workspace{} = workspace} =
               Composer.update_workspace_permissions(workspace, "identity", "permission")

      assert workspace.permissions == %{"identity" => "permission"}
    end

    test "update_workspace_permissions/2 with overwrites existing permissions" do
      workspace =
        workspace_fixture(%{
          permissions: %{"identity" => "permission"}
        })

      assert {:ok, %Workspace{} = workspace} =
               Composer.update_workspace_permissions(workspace, "identity", "another_permission")

      assert workspace.permissions == %{"identity" => "another_permission"}
    end

    test "delete_workspace/1 deletes the workspace" do
      workspace = workspace_fixture()
      assert {:ok, %Workspace{}} = Composer.delete_workspace(workspace)
      assert_raise Ecto.NoResultsError, fn -> Composer.get_workspace!(workspace.id) end
    end

    test "change_workspace/1 returns a workspace changeset" do
      workspace = workspace_fixture()
      assert %Ecto.Changeset{} = Composer.change_workspace(workspace)
    end

    test "check_workspace_permissions/2 returns the permission for the identity" do
      workspace = workspace_fixture(%{owner: "some owner"})
      assert Composer.check_workspace_permissions(workspace.id, "some owner") == "owner"
    end
  end

  describe "threats" do
    alias Valentine.Composer.Threat

    import Valentine.ComposerFixtures

    @invalid_attrs %{
      uuid: nil,
      status: nil,
      priority: nil,
      stride: nil,
      comments: nil,
      threat_source: nil,
      prerequisites: nil,
      threat_action: nil,
      threat_impact: nil,
      impacted_goal: nil,
      impacted_assets: nil,
      workspace_id: nil
    }

    test "list_threats/0 returns all threats" do
      threat = threat_fixture()
      assert Composer.list_threats() == [threat]
    end

    test "list_threats_by_workspace/2 returns all threats for a workspace" do
      threat = threat_fixture()
      assert hd(Composer.list_threats_by_workspace(threat.workspace_id)).id == threat.id
    end

    test "list_threats_by_workspace/2 returns all threats for a workspace and not other workspaces" do
      assert Composer.list_threats_by_workspace("00000000-0000-0000-0000-000000000000") == []
    end

    test "list_threats_by_workspace/2 returns all threats for a workspace based on a filter" do
      threat_fixture()
      threat = threat_fixture(%{status: :identified})

      assert hd(
               Composer.list_threats_by_workspace(threat.workspace_id, %{
                 status: ["identified"]
               })
             ).id == threat.id
    end

    test "get_threat!/1 returns the threat with given id" do
      threat = threat_fixture()
      assert Composer.get_threat!(threat.id) == threat
    end

    test "create_threat/1 with valid data creates a threat" do
      workspace = workspace_fixture()

      valid_attrs = %{
        workspace_id: workspace.id,
        status: :identified,
        priority: :high,
        stride: [:spoofing],
        comments: "some comments",
        threat_source: "some threat_source",
        prerequisites: "some prerequisites",
        threat_action: "some threat_action",
        threat_impact: "some threat_impact",
        impacted_goal: ["option1", "option2"],
        impacted_assets: ["option1", "option2"],
        tags: ["tag1", "tag2"]
      }

      assert {:ok, %Threat{} = threat} = Composer.create_threat(valid_attrs)
      assert threat.status == :identified
      assert threat.priority == :high
      assert threat.stride == [:spoofing]
      assert threat.comments == "some comments"
      assert threat.threat_source == "some threat_source"
      assert threat.prerequisites == "some prerequisites"
      assert threat.threat_action == "some threat_action"
      assert threat.threat_impact == "some threat_impact"
      assert threat.impacted_goal == ["option1", "option2"]
      assert threat.impacted_assets == ["option1", "option2"]
    end

    test "create_threat/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_threat(@invalid_attrs)
    end

    test "update_threat/2 with valid data updates the threat" do
      threat = threat_fixture()

      update_attrs = %{
        status: :resolved,
        priority: :low,
        stride: [:tampering],
        comments: "some updated comments",
        threat_source: "some updated threat_source",
        prerequisites: "some updated prerequisites",
        threat_action: "some updated threat_action",
        threat_impact: "some updated threat_impact",
        impacted_goal: ["option1"],
        impacted_assets: ["option1"],
        tags: ["tag1", "tag2"]
      }

      assert {:ok, %Threat{} = threat} = Composer.update_threat(threat, update_attrs)
      assert threat.status == :resolved
      assert threat.priority == :low
      assert threat.stride == [:tampering]
      assert threat.comments == "some updated comments"
      assert threat.threat_source == "some updated threat_source"
      assert threat.prerequisites == "some updated prerequisites"
      assert threat.threat_action == "some updated threat_action"
      assert threat.threat_impact == "some updated threat_impact"
      assert threat.impacted_goal == ["option1"]
      assert threat.impacted_assets == ["option1"]
    end

    test "update_threat/2 with invalid data returns error changeset" do
      threat = threat_fixture()
      assert {:error, %Ecto.Changeset{}} = Composer.update_threat(threat, @invalid_attrs)
      assert threat == Composer.get_threat!(threat.id)
    end

    test "delete_threat/1 deletes the threat" do
      threat = threat_fixture()
      assert {:ok, %Threat{}} = Composer.delete_threat(threat)
      assert_raise Ecto.NoResultsError, fn -> Composer.get_threat!(threat.id) end
    end

    test "change_threat/1 returns a threat changeset" do
      threat = threat_fixture()
      assert %Ecto.Changeset{} = Composer.change_threat(threat)
    end

    test "add_assumption_to_threat/2 adds an assumption to a threat" do
      threat = threat_fixture()
      assumption = assumption_fixture()

      assert {:ok, %Threat{} = threat} = Composer.add_assumption_to_threat(threat, assumption)
      assert threat.assumptions == [assumption]
    end

    test "add_assumption_to_threat/2 adds an assumption to existing threat assumptions" do
      threat = threat_fixture()
      assumption = assumption_fixture()

      Composer.add_assumption_to_threat(threat, assumption)

      assumption2 = assumption_fixture()

      assert {:ok, %Threat{} = threat} = Composer.add_assumption_to_threat(threat, assumption2)
      assert threat.assumptions == [assumption, assumption2]
    end

    test "remove_assumption_from_threat/2 removes an assumption from a threat" do
      threat = threat_fixture()
      assumption = assumption_fixture()

      {:ok, %Threat{} = threat} = Composer.add_assumption_to_threat(threat, assumption)

      assert threat.assumptions == [assumption]

      {:ok, %Threat{} = threat} = Composer.remove_assumption_from_threat(threat, assumption)

      assert threat.assumptions == []
    end

    test "add_mitigation_to_threat/2 adds an mitigation to a threat" do
      threat = threat_fixture()
      mitigation = mitigation_fixture()

      assert {:ok, %Threat{} = threat} = Composer.add_mitigation_to_threat(threat, mitigation)
      assert threat.mitigations == [mitigation]
    end

    test "add_mitigation_to_threat/2 adds an mitigation to existing threat mitigations" do
      threat = threat_fixture()
      mitigation = mitigation_fixture()

      Composer.add_mitigation_to_threat(threat, mitigation)

      mitigation2 = mitigation_fixture()

      assert {:ok, %Threat{} = threat} = Composer.add_mitigation_to_threat(threat, mitigation2)
      assert threat.mitigations == [mitigation, mitigation2]
    end

    test "remove_mitigation_from_threat/2 removes an mitigation from a threat" do
      threat = threat_fixture()
      mitigation = mitigation_fixture()

      {:ok, %Threat{} = threat} = Composer.add_mitigation_to_threat(threat, mitigation)

      assert threat.mitigations == [mitigation]

      {:ok, %Threat{} = threat} = Composer.remove_mitigation_from_threat(threat, mitigation)

      assert threat.mitigations == []
    end
  end

  describe "assumptions" do
    alias Valentine.Composer.Assumption

    import Valentine.ComposerFixtures

    @invalid_attrs %{comments: nil, content: nil, tags: nil}

    test "list_assumptions/0 returns all assumptions" do
      assumption = assumption_fixture()
      assert Composer.list_assumptions() == [assumption]
    end

    test "list_assumptions_by_workspace/2 returns all assumptions for a workspace" do
      assumption = assumption_fixture()
      assert Composer.list_assumptions_by_workspace(assumption.workspace_id) == [assumption]
    end

    test "list_assumptions_by_workspace/2 returns all assumptions for a workspace based on a filter" do
      assumption_fixture()
      assumption = assumption_fixture(%{status: :confirmed})

      assert Composer.list_assumptions_by_workspace(assumption.workspace_id, %{
               status: ["confirmed"]
             }) == [assumption]
    end

    test "list_assumptions_by_workspace/2 returns all assumptions for a workspace and not other workspaces" do
      assert Composer.list_assumptions_by_workspace("00000000-0000-0000-0000-000000000000") == []
    end

    test "get_assumption!/1 returns the assumption with given id" do
      assumption = assumption_fixture()
      assert Composer.get_assumption!(assumption.id) == assumption
    end

    test "create_assumption/1 with valid data creates a assumption" do
      workspace = workspace_fixture()

      valid_attrs = %{
        comments: "some comments",
        content: "some content",
        tags: ["option1", "option2"],
        workspace_id: workspace.id
      }

      assert {:ok, %Assumption{} = assumption} = Composer.create_assumption(valid_attrs)
      assert assumption.comments == "some comments"
      assert assumption.content == "some content"
      assert assumption.tags == ["option1", "option2"]
    end

    test "create_assumption/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_assumption(@invalid_attrs)
    end

    test "update_assumption/2 with valid data updates the assumption" do
      assumption = assumption_fixture()

      update_attrs = %{
        comments: "some updated comments",
        content: "some updated content",
        tags: ["option1"]
      }

      assert {:ok, %Assumption{} = assumption} =
               Composer.update_assumption(assumption, update_attrs)

      assert assumption.comments == "some updated comments"
      assert assumption.content == "some updated content"
      assert assumption.tags == ["option1"]
    end

    test "update_assumption/2 with invalid data returns error changeset" do
      assumption = assumption_fixture()
      assert {:error, %Ecto.Changeset{}} = Composer.update_assumption(assumption, @invalid_attrs)
      assert assumption == Composer.get_assumption!(assumption.id)
    end

    test "delete_assumption/1 deletes the assumption" do
      assumption = assumption_fixture()
      assert {:ok, %Assumption{}} = Composer.delete_assumption(assumption)
      assert_raise Ecto.NoResultsError, fn -> Composer.get_assumption!(assumption.id) end
    end

    test "change_assumption/1 returns a assumption changeset" do
      assumption = assumption_fixture()
      assert %Ecto.Changeset{} = Composer.change_assumption(assumption)
    end

    test "add_mitigation_to_assumption/2 adds an mitigation to a assumption" do
      assumption = assumption_fixture()
      mitigation = mitigation_fixture()

      assert {:ok, %Assumption{} = assumption} =
               Composer.add_mitigation_to_assumption(assumption, mitigation)

      assert assumption.mitigations == [mitigation]
    end

    test "add_mitigation_to_assumption/2 adds an mitigation to existing assumption mitigations" do
      assumption = assumption_fixture()
      mitigation = mitigation_fixture()

      Composer.add_mitigation_to_assumption(assumption, mitigation)

      mitigation2 = mitigation_fixture()

      assert {:ok, %Assumption{} = assumption} =
               Composer.add_mitigation_to_assumption(assumption, mitigation2)

      assert assumption.mitigations == [mitigation, mitigation2]
    end

    test "remove_mitigation_from_assumption/2 removes an mitigation from a assumption" do
      assumption = assumption_fixture()
      mitigation = mitigation_fixture()

      {:ok, %Assumption{} = assumption} =
        Composer.add_mitigation_to_assumption(assumption, mitigation)

      assert assumption.mitigations == [mitigation]

      {:ok, %Assumption{} = assumption} =
        Composer.remove_mitigation_from_assumption(assumption, mitigation)

      assert assumption.mitigations == []
    end

    test "add_threat_to_assumption/2 adds an threat to a assumption" do
      assumption = assumption_fixture()
      threat = threat_fixture()

      assert {:ok, %Assumption{} = assumption} =
               Composer.add_threat_to_assumption(assumption, threat)

      assert assumption.threats == [threat]
    end

    test "add_threat_to_assumption/2 adds an threat to existing assumption threats" do
      assumption = assumption_fixture()
      threat = threat_fixture()

      Composer.add_threat_to_assumption(assumption, threat)

      threat2 = threat_fixture()

      assert {:ok, %Assumption{} = assumption} =
               Composer.add_threat_to_assumption(assumption, threat2)

      assert assumption.threats == [threat, threat2]
    end

    test "remove_threat_from_assumption/2 removes an threat from a assumption" do
      assumption = assumption_fixture()
      threat = threat_fixture()

      {:ok, %Assumption{} = assumption} =
        Composer.add_threat_to_assumption(assumption, threat)

      assert assumption.threats == [threat]

      {:ok, %Assumption{} = assumption} =
        Composer.remove_threat_from_assumption(assumption, threat)

      assert assumption.threats == []
    end
  end

  describe "mitigations" do
    alias Valentine.Composer.Mitigation

    import Valentine.ComposerFixtures

    @invalid_attrs %{comments: nil, content: nil, status: nil, tags: nil}

    test "list_mitigations/0 returns all mitigations" do
      mitigation = mitigation_fixture()
      assert Composer.list_mitigations() == [mitigation]
    end

    test "list_mitigations_by_workspace/2 returns all mitigations for a workspace" do
      mitigation = mitigation_fixture()
      assert Composer.list_mitigations_by_workspace(mitigation.workspace_id) == [mitigation]
    end

    test "list_mitigations_by_workspace/2 returns all mitigations for a workspace based on a filter" do
      mitigation_fixture()
      mitigation = mitigation_fixture(%{status: :identified})

      assert Composer.list_mitigations_by_workspace(mitigation.workspace_id, %{
               status: ["identified"]
             }) == [mitigation]
    end

    test "list_mitigations_by_workspace/2 returns all mitigations for a workspace and not other workspaces" do
      assert Composer.list_mitigations_by_workspace("00000000-0000-0000-0000-000000000000") == []
    end

    test "get_mitigation!/1 returns the mitigation with given id" do
      mitigation = mitigation_fixture()
      assert Composer.get_mitigation!(mitigation.id) == mitigation
    end

    test "create_mitigation/1 with valid data creates a mitigation" do
      workspace = workspace_fixture()

      valid_attrs = %{
        comments: "some comments",
        content: "some content",
        status: :identified,
        tags: ["option1", "option2"],
        workspace_id: workspace.id
      }

      assert {:ok, %Mitigation{} = mitigation} = Composer.create_mitigation(valid_attrs)
      assert mitigation.comments == "some comments"
      assert mitigation.content == "some content"
      assert mitigation.tags == ["option1", "option2"]
    end

    test "create_mitigation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_mitigation(@invalid_attrs)
    end

    test "update_mitigation/2 with valid data updates the mitigation" do
      mitigation = mitigation_fixture()

      update_attrs = %{
        comments: "some updated comments",
        content: "some updated content",
        status: :resolved,
        tags: ["option1"]
      }

      assert {:ok, %Mitigation{} = mitigation} =
               Composer.update_mitigation(mitigation, update_attrs)

      assert mitigation.comments == "some updated comments"
      assert mitigation.content == "some updated content"
      assert mitigation.status == :resolved
      assert mitigation.tags == ["option1"]
    end

    test "update_mitigation/2 with invalid data returns error changeset" do
      mitigation = mitigation_fixture()
      assert {:error, %Ecto.Changeset{}} = Composer.update_mitigation(mitigation, @invalid_attrs)
      assert mitigation == Composer.get_mitigation!(mitigation.id)
    end

    test "delete_mitigation/1 deletes the mitigation" do
      mitigation = mitigation_fixture()
      assert {:ok, %Mitigation{}} = Composer.delete_mitigation(mitigation)
      assert_raise Ecto.NoResultsError, fn -> Composer.get_mitigation!(mitigation.id) end
    end

    test "change_mitigation/1 returns a mitigation changeset" do
      mitigation = mitigation_fixture()
      assert %Ecto.Changeset{} = Composer.change_mitigation(mitigation)
    end

    test "add_assumption_to_mitigation/2 adds an assumption to a mitigation" do
      mitigation = mitigation_fixture()
      assumption = assumption_fixture()

      assert {:ok, %Mitigation{} = mitigation} =
               Composer.add_assumption_to_mitigation(mitigation, assumption)

      assert mitigation.assumptions == [assumption]
    end

    test "add_assumption_to_mitigation/2 adds an assumption to existing mitigation assumptions" do
      mitigation = mitigation_fixture()
      assumption = assumption_fixture()

      Composer.add_assumption_to_mitigation(mitigation, assumption)

      assumption2 = assumption_fixture()

      assert {:ok, %Mitigation{} = mitigation} =
               Composer.add_assumption_to_mitigation(mitigation, assumption2)

      assert mitigation.assumptions == [assumption, assumption2]
    end

    test "remove_assumption_from_mitigation/2 removes an assumption from a mitigation" do
      mitigation = mitigation_fixture()
      assumption = assumption_fixture()

      {:ok, %Mitigation{} = mitigation} =
        Composer.add_assumption_to_mitigation(mitigation, assumption)

      assert mitigation.assumptions == [assumption]

      {:ok, %Mitigation{} = mitigation} =
        Composer.remove_assumption_from_mitigation(mitigation, assumption)

      assert mitigation.assumptions == []
    end

    test "add_threat_to_mitigation/2 adds an threat to a mitigation" do
      mitigation = mitigation_fixture()
      threat = threat_fixture()

      assert {:ok, %Mitigation{} = mitigation} =
               Composer.add_threat_to_mitigation(mitigation, threat)

      assert mitigation.threats == [threat]
    end

    test "add_threat_to_mitigation/2 adds an threat to existing mitigation threats" do
      mitigation = mitigation_fixture()
      threat = threat_fixture()

      Composer.add_threat_to_mitigation(mitigation, threat)

      threat2 = threat_fixture()

      assert {:ok, %Mitigation{} = mitigation} =
               Composer.add_threat_to_mitigation(mitigation, threat2)

      assert mitigation.threats == [threat, threat2]
    end

    test "remove_threat_from_mitigation/2 removes an threat from a mitigation" do
      mitigation = mitigation_fixture()
      threat = threat_fixture()

      {:ok, %Mitigation{} = mitigation} =
        Composer.add_threat_to_mitigation(mitigation, threat)

      assert mitigation.threats == [threat]

      {:ok, %Mitigation{} = mitigation} =
        Composer.remove_threat_from_mitigation(mitigation, threat)

      assert mitigation.threats == []
    end
  end

  describe "application_informations" do
    alias Valentine.Composer.ApplicationInformation

    import Valentine.ComposerFixtures

    @invalid_attrs %{comments: nil, content: nil, status: nil, tags: nil, workspace_id: nil}

    test "list_application_informations/0 returns all application_informations" do
      application_information = application_information_fixture()
      assert Composer.list_application_informations() == [application_information]
    end

    test "get_application_information!/1 returns the application_information with given id" do
      application_information = application_information_fixture()

      assert Composer.get_application_information!(application_information.id) ==
               application_information
    end

    test "create_application_information/1 with valid data creates a application_information" do
      workspace = workspace_fixture()

      valid_attrs = %{
        content: "some content",
        workspace_id: workspace.id
      }

      assert {:ok, %ApplicationInformation{} = application_information} =
               Composer.create_application_information(valid_attrs)

      assert application_information.content == "some content"
    end

    test "create_application_information/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_application_information(@invalid_attrs)
    end

    test "update_application_information/2 with valid data updates the application_information" do
      application_information = application_information_fixture()

      update_attrs = %{
        content: "some updated content"
      }

      assert {:ok, %ApplicationInformation{} = application_information} =
               Composer.update_application_information(application_information, update_attrs)

      assert application_information.content == "some updated content"
    end

    test "update_application_information/2 with invalid data returns error changeset" do
      application_information = application_information_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Composer.update_application_information(application_information, @invalid_attrs)

      assert application_information ==
               Composer.get_application_information!(application_information.id)
    end

    test "delete_application_information/1 deletes the application_information" do
      application_information = application_information_fixture()

      assert {:ok, %ApplicationInformation{}} =
               Composer.delete_application_information(application_information)

      assert_raise Ecto.NoResultsError, fn ->
        Composer.get_application_information!(application_information.id)
      end
    end

    test "change_application_information/1 returns a application_information changeset" do
      application_information = application_information_fixture()
      assert %Ecto.Changeset{} = Composer.change_application_information(application_information)
    end
  end

  describe "data_flow_diagrams" do
    alias Valentine.Composer.DataFlowDiagram

    import Valentine.ComposerFixtures

    @invalid_attrs %{comments: nil, content: nil, status: nil, tags: nil}

    test "list_data_flow_diagrams/0 returns all data_flow_diagrams" do
      data_flow_diagram = data_flow_diagram_fixture()

      assert hd(Composer.list_data_flow_diagrams()).id == data_flow_diagram.id
    end

    test "get_data_flow_diagram_by_workspace_id/1 returns the data_flow_diagram with given workspace_id" do
      data_flow_diagram = data_flow_diagram_fixture()

      assert Composer.get_data_flow_diagram_by_workspace_id(data_flow_diagram.workspace_id).id ==
               data_flow_diagram.id
    end

    test "get_data_flow_diagram!/1 returns the data_flow_diagram with given id" do
      data_flow_diagram = data_flow_diagram_fixture()

      assert Composer.get_data_flow_diagram!(data_flow_diagram.id).id ==
               data_flow_diagram.id
    end

    test "create_data_flow_diagram/1 with valid data creates a data_flow_diagram" do
      workspace = workspace_fixture()

      valid_attrs = %{
        edges: %{},
        nodes: %{},
        workspace_id: workspace.id
      }

      assert {:ok, %DataFlowDiagram{} = data_flow_diagram} =
               Composer.create_data_flow_diagram(valid_attrs)

      assert data_flow_diagram.edges == %{}
      assert data_flow_diagram.nodes == %{}
    end

    test "create_data_flow_diagram/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_data_flow_diagram(@invalid_attrs)
    end

    test "update_data_flow_diagram/2 with valid data updates the data_flow_diagram" do
      data_flow_diagram = data_flow_diagram_fixture()

      update_attrs = %{
        edges: %{"foo" => "bar"}
      }

      assert {:ok, %DataFlowDiagram{} = data_flow_diagram} =
               Composer.update_data_flow_diagram(data_flow_diagram, update_attrs)

      assert data_flow_diagram.edges == %{"foo" => "bar"}
    end

    test "update_data_flow_diagram/2 with invalid data returns error changeset" do
      data_flow_diagram = data_flow_diagram_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Composer.update_data_flow_diagram(data_flow_diagram, %{edges: nil})

      assert data_flow_diagram ==
               Composer.get_data_flow_diagram!(data_flow_diagram.id)
    end

    test "delete_data_flow_diagram/1 deletes the data_flow_diagram" do
      data_flow_diagram = data_flow_diagram_fixture()

      assert {:ok, %DataFlowDiagram{}} =
               Composer.delete_data_flow_diagram(data_flow_diagram)

      assert_raise Ecto.NoResultsError, fn ->
        Composer.get_data_flow_diagram!(data_flow_diagram.id)
      end
    end

    test "change_data_flow_diagram/1 returns a data_flow_diagram changeset" do
      data_flow_diagram = data_flow_diagram_fixture()
      assert %Ecto.Changeset{} = Composer.change_data_flow_diagram(data_flow_diagram)
    end
  end

  describe "architectures" do
    alias Valentine.Composer.Architecture

    import Valentine.ComposerFixtures

    @invalid_attrs %{comments: nil, content: nil, status: nil, tags: nil, workspace_id: nil}

    test "list_architectures/0 returns all architectures" do
      architecture = architecture_fixture()
      assert Composer.list_architectures() == [architecture]
    end

    test "get_architecture!/1 returns the architecture with given id" do
      architecture = architecture_fixture()

      assert Composer.get_architecture!(architecture.id) ==
               architecture
    end

    test "create_architecture/1 with valid data creates a architecture" do
      workspace = workspace_fixture()

      valid_attrs = %{
        content: "some content",
        workspace_id: workspace.id
      }

      assert {:ok, %Architecture{} = architecture} =
               Composer.create_architecture(valid_attrs)

      assert architecture.content == "some content"
    end

    test "create_architecture/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_architecture(@invalid_attrs)
    end

    test "update_architecture/2 with valid data updates the architecture" do
      architecture = architecture_fixture()

      update_attrs = %{
        content: "some updated content"
      }

      assert {:ok, %Architecture{} = architecture} =
               Composer.update_architecture(architecture, update_attrs)

      assert architecture.content == "some updated content"
    end

    test "update_architecture/2 with invalid data returns error changeset" do
      architecture = architecture_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Composer.update_architecture(architecture, @invalid_attrs)

      assert architecture ==
               Composer.get_architecture!(architecture.id)
    end

    test "delete_architecture/1 deletes the architecture" do
      architecture = architecture_fixture()

      assert {:ok, %Architecture{}} =
               Composer.delete_architecture(architecture)

      assert_raise Ecto.NoResultsError, fn ->
        Composer.get_architecture!(architecture.id)
      end
    end

    test "change_architecture/1 returns a architecture changeset" do
      architecture = architecture_fixture()
      assert %Ecto.Changeset{} = Composer.change_architecture(architecture)
    end
  end

  describe "reference_pack_items" do
    alias Valentine.Composer.Assumption
    alias Valentine.Composer.Mitigation
    alias Valentine.Composer.ReferencePackItem

    import Valentine.ComposerFixtures

    @invalid_attrs %{
      name: nil,
      description: nil,
      collection_id: nil,
      collection_type: nil,
      collection_name: nil,
      data: nil
    }

    test "list_reference_pack_items/0 returns all reference_pack_items" do
      reference_pack_item = reference_pack_item_fixture()
      assert Composer.list_reference_pack_items() == [reference_pack_item]
    end

    test "list_reference_pack_items_by_collection/2 returns all reference_pack_items for a collection_id and collection_type" do
      reference_pack_item = reference_pack_item_fixture()

      assert Composer.list_reference_pack_items_by_collection(
               reference_pack_item.collection_id,
               reference_pack_item.collection_type
             ) == [reference_pack_item]
    end

    test "list_reference_packs/1 returns all the reference packs by type, collection, and name count" do
      reference_pack_item = reference_pack_item_fixture()

      assert Composer.list_reference_packs() == [
               %{
                 collection_id: reference_pack_item.collection_id,
                 collection_name: reference_pack_item.collection_name,
                 collection_type: reference_pack_item.collection_type,
                 count: 1
               }
             ]
    end

    test "get_reference_pack_item!/1 returns the reference_pack_item with given id" do
      reference_pack_item = reference_pack_item_fixture()

      assert Composer.get_reference_pack_item!(reference_pack_item.id) ==
               reference_pack_item
    end

    test "create_reference_pack_item/1 with valid data creates a reference_pack_item" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        collection_id: random_uuid(),
        collection_type: :assumption,
        collection_name: "some collection_name",
        data: %{}
      }

      assert {:ok, %ReferencePackItem{} = reference_pack_item} =
               Composer.create_reference_pack_item(valid_attrs)

      assert reference_pack_item.name == "some name"
    end

    test "create_reference_pack_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_reference_pack_item(@invalid_attrs)
    end

    test "update_reference_pack_item/2 with valid data updates the reference_pack_item" do
      reference_pack_item = reference_pack_item_fixture()

      update_attrs = %{
        name: "some updated name"
      }

      assert {:ok, %ReferencePackItem{} = reference_pack_item} =
               Composer.update_reference_pack_item(reference_pack_item, update_attrs)

      assert reference_pack_item.name == "some updated name"
    end

    test "update_reference_pack_item/2 with invalid data returns error changeset" do
      reference_pack_item = reference_pack_item_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Composer.update_reference_pack_item(reference_pack_item, @invalid_attrs)

      assert reference_pack_item ==
               Composer.get_reference_pack_item!(reference_pack_item.id)
    end

    test "delete_reference_pack_item/1 deletes the reference_pack_item" do
      reference_pack_item = reference_pack_item_fixture()

      assert {:ok, %ReferencePackItem{}} =
               Composer.delete_reference_pack_item(reference_pack_item)

      assert_raise Ecto.NoResultsError, fn ->
        Composer.get_reference_pack_item!(reference_pack_item.id)
      end
    end

    test "delete_reference_pack_collection" do
      reference_pack_item = reference_pack_item_fixture()

      assert {1, nil} =
               Composer.delete_reference_pack_collection(
                 reference_pack_item.collection_id,
                 reference_pack_item.collection_type
               )

      assert_raise Ecto.NoResultsError, fn ->
        Composer.get_reference_pack_item!(reference_pack_item.id)
      end
    end

    test "change_reference_pack_item/1 returns a reference_pack_item changeset" do
      reference_pack_item = reference_pack_item_fixture()
      assert %Ecto.Changeset{} = Composer.change_reference_pack_item(reference_pack_item)
    end

    test "add_reference_pack_item_to_workspace/2 adds a assumption item to a workspace" do
      reference_pack_item = reference_pack_item_fixture(collection_type: :assumption)
      workspace = workspace_fixture()

      assert {:ok, %Assumption{} = assumption} =
               Composer.add_reference_pack_item_to_workspace(workspace.id, reference_pack_item)

      workspace = Composer.get_workspace!(workspace.id, [:assumptions])

      assert workspace.assumptions == [assumption]
    end

    test "add_reference_pack_item_to_workspace/2 adds a mitigation item to a workspace" do
      reference_pack_item = reference_pack_item_fixture()
      workspace = workspace_fixture()

      assert {:ok, %Mitigation{} = mitigation} =
               Composer.add_reference_pack_item_to_workspace(workspace.id, reference_pack_item)

      workspace = Composer.get_workspace!(workspace.id, [:mitigations])

      assert workspace.mitigations == [mitigation]
    end
  end

  describe "controls" do
    alias Valentine.Composer.Control

    import Valentine.ComposerFixtures

    @invalid_attrs %{
      name: nil,
      description: nil,
      nist_id: nil,
      nist_family: nil,
      stride: nil,
      tags: nil
    }

    test "list_controls/0 returns all controls" do
      control = control_fixture()
      assert Composer.list_controls() == [control]
    end

    test "list_controls_by_filters/0 returns all controls with given tags" do
      control = control_fixture(tags: ["tag1", "tag2"])
      assert Composer.list_controls_by_filters(%{tags: control.tags}) == [control]
    end

    test "list_controls_by_filters/0 returns all controls with given tags and not other controls" do
      control_fixture(tags: ["tag1", "tag2"])
      assert Composer.list_controls_by_filters(%{tags: ["tag3"]}) == []
    end

    test "list_controls_by_filters/0, will filter by class" do
      control = control_fixture(tags: ["tag1", "tag2"], class: "some class")
      control_fixture(tags: ["tag1", "tag2"], class: "other class")

      assert Composer.list_controls_by_filters(%{classes: ["some class"]}) ==
               [control]
    end

    test "list_controls_by_filters/0 will optionally filter by class and family as well" do
      control = control_fixture(tags: ["tag1", "tag2"], class: "some class", nist_id: "AC-1")
      control_fixture(tags: ["tag1", "tag2"], class: "other class", nist_id: "AC-2")

      assert Composer.list_controls_by_filters(%{
               tags: control.tags,
               classes: ["some class"],
               nist_families: ["AC"]
             }) == [control]
    end

    test "list_control_families/0 returns all control families" do
      control_fixture(%{nist_id: "AC-1"})
      assert Composer.list_control_families() == ["AC"]
    end

    test "list_controls_in_families/1 returns all controls for a list of families" do
      control = control_fixture(%{nist_id: "AC-1"})
      family = control.nist_id |> String.split("-") |> hd
      assert Composer.list_controls_in_families([family]) == [control]
    end

    test "get_control!/1 returns the control with given id" do
      control = control_fixture()

      assert Composer.get_control!(control.id) ==
               control
    end

    test "create_control/1 with valid data creates a control" do
      valid_attrs = %{
        name: "some name",
        class: "some class",
        description: "some description",
        nist_id: "some nist_id",
        nist_family: "some nist_family",
        stride: [:spoofing],
        tags: ["tag1", "tag2"]
      }

      assert {:ok, %Control{} = control} =
               Composer.create_control(valid_attrs)

      assert control.name == "some name"
    end

    test "create_control/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_control(@invalid_attrs)
    end

    test "update_control/2 with valid data updates the control" do
      control = control_fixture()

      update_attrs = %{
        name: "some updated name"
      }

      assert {:ok, %Control{} = control} =
               Composer.update_control(control, update_attrs)

      assert control.name == "some updated name"
    end

    test "update_control/2 with invalid data returns error changeset" do
      control = control_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Composer.update_control(control, @invalid_attrs)

      assert control ==
               Composer.get_control!(control.id)
    end

    test "delete_control/1 deletes the control" do
      control = control_fixture()

      assert {:ok, %Control{}} =
               Composer.delete_control(control)

      assert_raise Ecto.NoResultsError, fn ->
        Composer.get_control!(control.id)
      end
    end

    test "change_control/1 returns a control changeset" do
      control = control_fixture()
      assert %Ecto.Changeset{} = Composer.change_control(control)
    end
  end

  describe "users" do
    alias Valentine.Composer.User

    import Valentine.ComposerFixtures

    @invalid_attrs %{email: "an invalid email"}

    test "list_users/0 returns all users sorted by email" do
      users = [
        user_fixture(%{email: "z.user@localhost"}),
        user_fixture(%{email: "a.user@localhost"}),
        user_fixture(%{email: "m.user@localhost"})
      ]

      assert Composer.list_users() == Enum.sort_by(users, & &1.email)
    end

    test "get_user/1 returns the user with given id" do
      user = user_fixture()

      assert Composer.get_user(user.email) ==
               user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{
        email: "some.user@localhost"
      }

      assert {:ok, %User{} = user} =
               Composer.create_user(valid_attrs)

      assert user.email == "some.user@localhost"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()

      updated_at = user.updated_at

      update_attrs = %{
        updated_at: DateTime.utc_now() |> DateTime.add(1, :day)
      }

      assert {:ok, %User{} = user} =
               Composer.update_user(user, update_attrs)

      assert user.email == user.email
      assert user.updated_at != updated_at
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Composer.update_user(user, @invalid_attrs)

      assert user ==
               Composer.get_user(user.email)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()

      assert {:ok, %User{}} =
               Composer.delete_user(user)

      assert Composer.get_user(user.email) == nil
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Composer.change_user(user)
    end
  end

  describe "api_keys" do
    alias Valentine.Composer.ApiKey

    import Valentine.ComposerFixtures

    @invalid_attrs %{owner: nil}

    test "list_api_keys/0 returns all api_keys" do
      api_key_fixture()
      assert length(Composer.list_api_keys()) > 0
    end

    test "list_api_keys_by_workspace/1 returns all api_keys for a workspace" do
      api_key = api_key_fixture()
      assert length(Composer.list_api_keys_by_workspace(api_key.workspace_id)) > 0
    end

    test "list_api_keys_by_workspace/1 returns all api_keys for a workspace and not other workspaces" do
      assert Composer.list_api_keys_by_workspace("00000000-0000-0000-0000-000000000000") == []
    end

    test "get_api_key/1 returns the api_key with given id" do
      api_key = api_key_fixture()

      assert Composer.get_api_key(api_key.id).id ==
               api_key.id
    end

    test "create_api_key/1 with valid data creates a api_key" do
      valid_attrs = %{
        owner: "some owner",
        label: "some label",
        key: "some key",
        status: :active
      }

      assert {:ok, %ApiKey{} = api_key} =
               Composer.create_api_key(valid_attrs)

      assert api_key.owner == "some owner"
    end

    test "create_api_key/1 with valid data automatically generates a key" do
      valid_attrs = %{
        owner: "some owner",
        label: "some label",
        key: "some key",
        status: :active
      }

      assert {:ok, %ApiKey{} = api_key} =
               Composer.create_api_key(valid_attrs)

      assert api_key.key != nil
    end

    test "create_api_key/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Composer.create_api_key(@invalid_attrs)
    end

    test "update_api_key/2 with valid data updates the api_key" do
      api_key = api_key_fixture()

      update_attrs = %{
        owner: "some updated owner"
      }

      assert {:ok, %ApiKey{} = api_key} =
               Composer.update_api_key(api_key, update_attrs)

      assert api_key.id == api_key.id
      assert api_key.owner == "some updated owner"
    end

    test "update_api_key/2 with invalid data returns error changeset" do
      api_key = api_key_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Composer.update_api_key(api_key, @invalid_attrs)

      assert api_key.id ==
               Composer.get_api_key(api_key.id).id
    end

    test "delete_api_key/1 deletes the api_key" do
      api_key = api_key_fixture()

      assert {:ok, %ApiKey{}} =
               Composer.delete_api_key(api_key)

      assert Composer.get_api_key(api_key.id) == nil
    end

    test "change_api_key/1 returns a api_key changeset" do
      api_key = api_key_fixture()
      assert %Ecto.Changeset{} = Composer.change_api_key(api_key)
    end
  end

  describe "evidence entity linking" do
    import Valentine.ComposerFixtures

    setup do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      assumption = assumption_fixture(%{workspace_id: workspace.id})
      threat = threat_fixture(%{workspace_id: workspace.id})
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      %{
        workspace: workspace,
        evidence: evidence,
        assumption: assumption,
        threat: threat,
        mitigation: mitigation
      }
    end

    test "add_assumption_to_evidence/2 successfully links", %{
      evidence: evidence,
      assumption: assumption
    } do
      assert {:ok, updated_evidence} = Composer.add_assumption_to_evidence(evidence, assumption)
      assert Enum.any?(updated_evidence.assumptions, &(&1.id == assumption.id))
    end

    test "add_assumption_to_evidence/2 returns evidence with preloaded assumptions", %{
      evidence: evidence,
      assumption: assumption
    } do
      {:ok, updated_evidence} = Composer.add_assumption_to_evidence(evidence, assumption)
      assert is_list(updated_evidence.assumptions)
      assert Enum.count(updated_evidence.assumptions) == 1
    end

    test "add_assumption_to_evidence/2 handles duplicates with on_conflict", %{
      evidence: evidence,
      assumption: assumption
    } do
      # Add once
      {:ok, _} = Composer.add_assumption_to_evidence(evidence, assumption)
      # Add again - should not error
      {:ok, updated_evidence} = Composer.add_assumption_to_evidence(evidence, assumption)
      # Should still only have one
      assert Enum.count(updated_evidence.assumptions) == 1
    end

    test "remove_assumption_from_evidence/2 unlinks assumption", %{
      evidence: evidence,
      assumption: assumption
    } do
      # First link
      {:ok, _} = Composer.add_assumption_to_evidence(evidence, assumption)
      # Then unlink
      {:ok, updated_evidence} = Composer.remove_assumption_from_evidence(evidence, assumption)
      refute Enum.any?(updated_evidence.assumptions, &(&1.id == assumption.id))
    end

    test "remove_assumption_from_evidence/2 returns updated evidence", %{
      evidence: evidence,
      assumption: assumption
    } do
      {:ok, _} = Composer.add_assumption_to_evidence(evidence, assumption)
      {:ok, updated_evidence} = Composer.remove_assumption_from_evidence(evidence, assumption)
      assert is_list(updated_evidence.assumptions)
      assert Enum.empty?(updated_evidence.assumptions)
    end

    test "remove_assumption_from_evidence/2 handles non-existent links", %{
      evidence: evidence,
      assumption: assumption
    } do
      # Try to remove a link that doesn't exist - should not error
      {:ok, updated_evidence} = Composer.remove_assumption_from_evidence(evidence, assumption)
      assert Enum.empty?(updated_evidence.assumptions)
    end

    test "add_threat_to_evidence/2 successfully links", %{evidence: evidence, threat: threat} do
      assert {:ok, updated_evidence} = Composer.add_threat_to_evidence(evidence, threat)
      assert Enum.any?(updated_evidence.threats, &(&1.id == threat.id))
    end

    test "add_threat_to_evidence/2 returns evidence with preloaded threats", %{
      evidence: evidence,
      threat: threat
    } do
      {:ok, updated_evidence} = Composer.add_threat_to_evidence(evidence, threat)
      assert is_list(updated_evidence.threats)
      assert Enum.count(updated_evidence.threats) == 1
    end

    test "add_threat_to_evidence/2 handles duplicates with on_conflict", %{
      evidence: evidence,
      threat: threat
    } do
      {:ok, _} = Composer.add_threat_to_evidence(evidence, threat)
      {:ok, updated_evidence} = Composer.add_threat_to_evidence(evidence, threat)
      assert Enum.count(updated_evidence.threats) == 1
    end

    test "remove_threat_from_evidence/2 unlinks threat", %{evidence: evidence, threat: threat} do
      {:ok, _} = Composer.add_threat_to_evidence(evidence, threat)
      {:ok, updated_evidence} = Composer.remove_threat_from_evidence(evidence, threat)
      refute Enum.any?(updated_evidence.threats, &(&1.id == threat.id))
    end

    test "remove_threat_from_evidence/2 returns updated evidence", %{
      evidence: evidence,
      threat: threat
    } do
      {:ok, _} = Composer.add_threat_to_evidence(evidence, threat)
      {:ok, updated_evidence} = Composer.remove_threat_from_evidence(evidence, threat)
      assert is_list(updated_evidence.threats)
      assert Enum.empty?(updated_evidence.threats)
    end

    test "remove_threat_from_evidence/2 handles non-existent links", %{
      evidence: evidence,
      threat: threat
    } do
      {:ok, updated_evidence} = Composer.remove_threat_from_evidence(evidence, threat)
      assert Enum.empty?(updated_evidence.threats)
    end

    test "add_mitigation_to_evidence/2 successfully links", %{
      evidence: evidence,
      mitigation: mitigation
    } do
      assert {:ok, updated_evidence} = Composer.add_mitigation_to_evidence(evidence, mitigation)
      assert Enum.any?(updated_evidence.mitigations, &(&1.id == mitigation.id))
    end

    test "add_mitigation_to_evidence/2 returns evidence with preloaded mitigations", %{
      evidence: evidence,
      mitigation: mitigation
    } do
      {:ok, updated_evidence} = Composer.add_mitigation_to_evidence(evidence, mitigation)
      assert is_list(updated_evidence.mitigations)
      assert Enum.count(updated_evidence.mitigations) == 1
    end

    test "add_mitigation_to_evidence/2 handles duplicates with on_conflict", %{
      evidence: evidence,
      mitigation: mitigation
    } do
      {:ok, _} = Composer.add_mitigation_to_evidence(evidence, mitigation)
      {:ok, updated_evidence} = Composer.add_mitigation_to_evidence(evidence, mitigation)
      assert Enum.count(updated_evidence.mitigations) == 1
    end

    test "remove_mitigation_from_evidence/2 unlinks mitigation", %{
      evidence: evidence,
      mitigation: mitigation
    } do
      {:ok, _} = Composer.add_mitigation_to_evidence(evidence, mitigation)
      {:ok, updated_evidence} = Composer.remove_mitigation_from_evidence(evidence, mitigation)
      refute Enum.any?(updated_evidence.mitigations, &(&1.id == mitigation.id))
    end

    test "remove_mitigation_from_evidence/2 returns updated evidence", %{
      evidence: evidence,
      mitigation: mitigation
    } do
      {:ok, _} = Composer.add_mitigation_to_evidence(evidence, mitigation)
      {:ok, updated_evidence} = Composer.remove_mitigation_from_evidence(evidence, mitigation)
      assert is_list(updated_evidence.mitigations)
      assert Enum.empty?(updated_evidence.mitigations)
    end

    test "remove_mitigation_from_evidence/2 handles non-existent links", %{
      evidence: evidence,
      mitigation: mitigation
    } do
      {:ok, updated_evidence} = Composer.remove_mitigation_from_evidence(evidence, mitigation)
      assert Enum.empty?(updated_evidence.mitigations)
    end

    test "get_evidence!/2 with preload list loads associations", %{evidence: evidence} do
      loaded_evidence =
        Composer.get_evidence!(evidence.id, [:assumptions, :threats, :mitigations])

      assert is_list(loaded_evidence.assumptions)
      assert is_list(loaded_evidence.threats)
      assert is_list(loaded_evidence.mitigations)
    end

    test "get_evidence!/2 with nil preload returns basic evidence", %{evidence: evidence} do
      loaded_evidence = Composer.get_evidence!(evidence.id, nil)
      assert loaded_evidence.id == evidence.id
      # Associations should not be loaded
      assert %Ecto.Association.NotLoaded{} = loaded_evidence.assumptions
    end
  end
end
