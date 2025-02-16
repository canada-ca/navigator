defmodule ValentineWeb.WorkspaceLive.Import.TcImportTest do
  use Valentine.DataCase

  alias ValentineWeb.WorkspaceLive.Import.TcImport
  alias Valentine.Composer
  alias Valentine.Repo

  @valid_json """
  {
    "schema": "1.0",
    "applicationInfo": {
      "name": "Test Application",
      "description": "This is a test description"
    },
    "architecture": {
      "description": "This is a test architecture",
      "image": "base64image"
    },
    "dataflow": {},
    "assumptions": [
      {
        "id": "a1",
        "numericId": 1,
        "content": "Test assumption",
        "metadata": [
          {"key": "Comments", "value": "Test comment"}
        ],
        "tags": ["test"]
      }
    ],
    "mitigations": [
      {
        "id": "m1",
        "numericId": 1,
        "content": "Test mitigation",
        "metadata": [
          {"key": "Comments", "value": "Test comment"}
        ],
        "tags": ["test"]
      }
    ],
    "threats": [
      {
        "id": "t1",
        "numericId": 1,
        "threatSource": "Test source",
        "prerequisites": "Test prerequisites",
        "threatAction": "Test action",
        "threatImpact": "Test impact",
        "impactedGoal": ["Test goal"],
        "impactedAssets": ["Test assets"],
        "status": "threatIdentified",
        "metadata": [
          {"key": "Comments", "value": "Test comment"},
          {"key": "Priority", "value": "High"},
          {"key": "STRIDE", "value": ["S", "T"]}
        ],
        "tags": ["test"]
      }
    ],
    "assumptionLinks": [
      {
        "type": "Threat",
        "linkedId": "t1",
        "assumptionId": "a1"
      },
      {
        "type": "Mitigation",
        "linkedId": "m1",
        "assumptionId": "a1"
      }
    ],
    "mitigationLinks": [
      {
        "linkedId": "t1",
        "mitigationId": "m1"
      }
    ]
  }
  """

  describe "validate/1" do
    test "returns ok with valid JSON" do
      assert {:ok, data} = TcImport.validate(@valid_json)
      assert data["applicationInfo"]["name"] == "Test Application"
    end

    test "returns error with invalid JSON" do
      assert {:error, "Invalid JSON"} = TcImport.validate("{invalid json}")
    end

    test "returns error when required fields are missing" do
      incomplete_json = """
      {
        "applicationInfo": {},
        "architecture": {}
      }
      """

      assert {:error, message} = TcImport.validate(incomplete_json)
      assert message =~ "Missing required fields"
    end
  end

  describe "build_workspace/1" do
    setup do
      {:ok, data} = Jason.decode(@valid_json)
      %{data: data}
    end

    test "creates a workspace with all components", %{data: data} do
      assert {:ok, workspace} = TcImport.build_workspace(data, "some owner")

      # Verify workspace
      assert workspace.name == "Test Application"

      # Verify application info
      app_info = Repo.get_by(Composer.ApplicationInformation, workspace_id: workspace.id)
      assert app_info.content =~ "This is a test description"

      # Verify architecture
      architecture = Repo.get_by(Composer.Architecture, workspace_id: workspace.id)
      assert architecture.content =~ "This is a test architecture"

      assert architecture.content =~
               "<p><img src=\"base64image\" alt=\"Architecture Diagram\" /></p>"

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
        "schema" => "1.0",
        "applicationInfo" => %{},
        "architecture" => %{},
        "dataflow" => %{},
        "assumptions" => [],
        "mitigations" => [],
        "threats" => [],
        "assumptionLinks" => [],
        "mitigationLinks" => []
      }

      assert {:ok, workspace} = TcImport.build_workspace(minimal_data, "some owner")
      assert workspace.name == "Untitled Workspace"
    end
  end

  describe "process_tc_file/1" do
    setup do
      path = "test.json"
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "successfully imports valid JSON file", %{path: path} do
      File.write!(path, @valid_json)
      assert {:ok, {:ok, workspace}} = TcImport.process_tc_file(path, "some owner")
      assert workspace.name == "Test Application"
    end

    test "handles missing file gracefully" do
      assert {:ok, {:error, _}} = TcImport.process_tc_file("nonexistent.json", "some owner")
    end

    test "handles invalid JSON file", %{path: path} do
      File.write!(path, "invalid json")
      assert {:ok, {:error, "Invalid JSON"}} = TcImport.process_tc_file(path, "some owner")
    end
  end
end
