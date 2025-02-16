defmodule ValentineWeb.WorkspaceLive.Import.HelperTest do
  use Valentine.DataCase

  alias ValentineWeb.WorkspaceLive.Import.Helper

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
          "threats": [],
          "mitigations": []
        }
      ],
      "mitigations": [
        {
          "id": "m1",
          "content": "Test mitigation",
          "comments": "Test comment",
          "tags": ["test"],
          "assumptions": [],
          "threats": []
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
          "assumptions": [],
          "mitigations": []
        }
      ]
    }
  }
  """

  @valid_tc_json """
  {
    "schema": "1.0",
    "applicationInfo": {
      "name": "Test TC Application",
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

  describe "import_file/1 for threat composer " do
    setup do
      path = "test.tc.json"
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "successfully imports valid JSON file", %{path: path} do
      File.write!(path, @valid_tc_json)
      assert {:ok, {:ok, workspace}} = Helper.import_file(path, path, "some owner")
      assert workspace.name == "Test TC Application"
    end
  end

  describe "import_file/1 for json " do
    setup do
      path = "test.json"
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "successfully imports valid JSON file", %{path: path} do
      File.write!(path, @valid_json)
      assert {:ok, {:ok, workspace}} = Helper.import_file(path, path, "some owner")
      assert workspace.name == "Test Application"
    end
  end
end
