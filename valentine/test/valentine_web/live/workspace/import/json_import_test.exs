defmodule ValentineWeb.WorkspaceLive.Import.JsonImportTest do
  use Valentine.DataCase

  alias ValentineWeb.WorkspaceLive.Import.JsonImport
  alias Valentine.Composer
  alias Valentine.Repo

  @valid_json """
  {
    "workspace": {
      "name": "Test Application",
      "application_information": {
        "content": "This is a test description"
      },
      "architecture": {
        "content": "This is a test architecture"
      },
      "data_flow_diagram": {},
      "assumptions": [
        {
          "id": "a1",
          "content": "Test assumption",
          "comments": "Test comment",
          "tags": ["test"],
          "threats": ["t1"],
          "mitigations": ["m1"]
        }
      ],
      "mitigations": [
        {
          "id": "m1",
          "content": "Test mitigation",
          "comments": "Test comment",
          "tags": ["test"],
          "assumptions": ["a1"],
          "threats": ["t1"]
        }
      ],
      "threats": [
        {
          "id": "t1",
          "threat_source": "Test source",
          "prerequisites": "Test prerequisites",
          "threat_action": "Test action",
          "threat_impact": "Test impact",
          "impacted_goal": ["Test goal"],
          "impacted_assets": ["Test assets"],
          "status": "identified",
          "comments": "Test comment",
          "priority": "high",
          "stride": ["spoofing", "tampering"],
          "tags": ["test"],
          "assumptions": ["a1"],
          "mitigations": ["m1"]
        }
      ]
    }
  }
  """

  describe "validate/1" do
    test "returns ok with valid JSON" do
      assert {:ok, data} = JsonImport.validate(@valid_json)
      assert data["name"] == "Test Application"
    end

    test "returns error with invalid JSON" do
      assert {:error, "Invalid JSON"} = JsonImport.validate("{invalid json}")
    end

    test "returns error when required fields are missing" do
      incomplete_json = """
      {
        "workspace": {
          "application_information": {},
          "architecture": {}
        }
      }
      """

      assert {:error, message} = JsonImport.validate(incomplete_json)
      assert message =~ "Missing required fields"
    end
  end

  describe "build_workspace/1" do
    setup do
      {:ok, data} = Jason.decode(@valid_json)
      %{data: data}
    end

    test "creates a workspace with all components", %{data: data} do
      assert {:ok, workspace} = JsonImport.build_workspace(data["workspace"], "some owner")

      # Verify workspace
      assert workspace.name == "Test Application"

      # Verify application info
      app_info = Repo.get_by(Composer.ApplicationInformation, workspace_id: workspace.id)
      assert app_info.content =~ "This is a test description"

      # Verify architecture
      architecture = Repo.get_by(Composer.Architecture, workspace_id: workspace.id)
      assert architecture.content =~ "This is a test architecture"

      # Verify assumption
      assumption = Repo.get_by(Composer.Assumption, workspace_id: workspace.id)
      assert assumption.content == "Test assumption"
      assert assumption.numeric_id == 1
      assert assumption.comments == "Test comment"
      assert assumption.tags == ["test"]

      # Verify mitigation
      mitigation = Repo.get_by(Composer.Mitigation, workspace_id: workspace.id)
      assert mitigation.content == "Test mitigation"
      assert mitigation.numeric_id == 1
      assert mitigation.comments == "Test comment"
      assert mitigation.tags == ["test"]

      # Verify threat
      threat = Repo.get_by(Composer.Threat, workspace_id: workspace.id)
      assert threat.threat_source == "Test source"
      assert threat.prerequisites == "Test prerequisites"
      assert threat.threat_action == "Test action"
      assert threat.threat_impact == "Test impact"
      assert threat.impacted_goal == ["Test goal"]
      assert threat.impacted_assets == ["Test assets"]
      assert threat.comments == "Test comment"
      assert threat.tags == ["test"]
      assert threat.status == :identified
      assert threat.priority == :high
      assert threat.stride == [:spoofing, :tampering]

      # Verify relationships
      assert Repo.get_by(Composer.AssumptionThreat,
               assumption_id: assumption.id,
               threat_id: threat.id
             )

      assert Repo.get_by(Composer.AssumptionMitigation,
               assumption_id: assumption.id,
               mitigation_id: mitigation.id
             )

      assert Repo.get_by(Composer.MitigationThreat,
               mitigation_id: mitigation.id,
               threat_id: threat.id
             )
    end

    test "creates workspace with minimal data" do
      minimal_data = %{
        "name" => "Untitled Workspace",
        "application_information" => %{},
        "architecture" => %{},
        "data_flow_diagram" => %{},
        "assumptions" => [],
        "mitigations" => [],
        "threats" => []
      }

      assert {:ok, workspace} = JsonImport.build_workspace(minimal_data, "some owner")
      assert workspace.name == "Untitled Workspace"
    end
  end

  describe "process_json_file/1" do
    setup do
      path = "test.json"
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "successfully imports valid JSON file", %{path: path} do
      File.write!(path, @valid_json)
      assert {:ok, {:ok, workspace}} = JsonImport.process_json_file(path, "some owner")
      assert workspace.name == "Test Application"
    end

    test "handles missing file gracefully" do
      assert {:ok, {:error, _}} = JsonImport.process_json_file("nonexistent.json", "some owner")
    end

    test "handles invalid JSON file", %{path: path} do
      File.write!(path, "invalid json")
      assert {:ok, {:error, "Invalid JSON"}} = JsonImport.process_json_file(path, "some owner")
    end
  end
end
