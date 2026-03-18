defmodule Valentine.Composer.WorkspaceTest do
  use ValentineWeb.ConnCase

  alias Valentine.Composer.Workspace
  alias Valentine.Composer.Assumption
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.Threat
  alias Valentine.Composer.Evidence

  describe "check_workspace_permissions" do
    test "returns owner if the identity matches the workspace owner" do
      workspace = %Workspace{owner: "user1"}
      assert Workspace.check_workspace_permissions(workspace, "user1") == "owner"
    end

    test "returns the permissions for the identity if it doesn't match the workspace owner" do
      workspace = %Workspace{
        owner: "user1",
        permissions: %{"user2" => "read"}
      }

      assert Workspace.check_workspace_permissions(workspace, "user1") == "owner"
      assert Workspace.check_workspace_permissions(workspace, "user2") == "read"
      assert Workspace.check_workspace_permissions(workspace, "user3") == nil
    end

    test "returns nil if the identity doesn't match the workspace owner and there are no permissions" do
      workspace = %Workspace{owner: "user1"}
      assert Workspace.check_workspace_permissions(workspace, "user2") == nil
    end
  end

  describe "get_tagged_with_controls/1" do
    test "filters out items without tags" do
      collection = [
        %Assumption{tags: ["AC-1"]},
        %Mitigation{tags: ["AC-2"]},
        %Threat{tags: ["AC-3"]},
        %Assumption{tags: nil},
        %Mitigation{tags: ["AC-1"]}
      ]

      assert Workspace.get_tagged_with_controls(collection) == %{
               "AC-1" => [%Assumption{tags: ["AC-1"]}, %Mitigation{tags: ["AC-1"]}],
               "AC-2" => [%Mitigation{tags: ["AC-2"]}],
               "AC-3" => [%Threat{tags: ["AC-3"]}]
             }
    end

    test "filters out tags that don't match the NIST ID regex" do
      collection = [
        %Assumption{tags: ["AC-1"]},
        %Mitigation{tags: ["AC-2"]},
        %Threat{tags: ["AC-3"]},
        %Assumption{tags: ["invalid"]},
        %Mitigation{tags: ["AC-1"]}
      ]

      assert Workspace.get_tagged_with_controls(collection) == %{
               "AC-1" => [%Assumption{tags: ["AC-1"]}, %Mitigation{tags: ["AC-1"]}],
               "AC-2" => [%Mitigation{tags: ["AC-2"]}],
               "AC-3" => [%Threat{tags: ["AC-3"]}]
             }
    end
  end

  describe "get_evidence_by_controls/1" do
    test "groups evidence by NIST control IDs" do
      collection = [
        %Evidence{id: "1", numeric_id: 1, name: "Evidence 1", nist_controls: ["AC-1"]},
        %Evidence{id: "2", numeric_id: 2, name: "Evidence 2", nist_controls: ["AC-2"]},
        %Evidence{id: "3", numeric_id: 3, name: "Evidence 3", nist_controls: ["AC-1", "SC-7"]}
      ]

      result = Workspace.get_evidence_by_controls(collection)

      # Order is reversed due to prepending for O(n) performance
      assert result["AC-1"] == [
               %Evidence{
                 id: "3",
                 numeric_id: 3,
                 name: "Evidence 3",
                 nist_controls: ["AC-1", "SC-7"]
               },
               %Evidence{id: "1", numeric_id: 1, name: "Evidence 1", nist_controls: ["AC-1"]}
             ]

      assert result["AC-2"] == [
               %Evidence{id: "2", numeric_id: 2, name: "Evidence 2", nist_controls: ["AC-2"]}
             ]

      assert result["SC-7"] == [
               %Evidence{
                 id: "3",
                 numeric_id: 3,
                 name: "Evidence 3",
                 nist_controls: ["AC-1", "SC-7"]
               }
             ]
    end

    test "filters out evidence without nist_controls" do
      collection = [
        %Evidence{id: "1", numeric_id: 1, name: "Evidence 1", nist_controls: ["AC-1"]},
        %Evidence{id: "2", numeric_id: 2, name: "Evidence 2", nist_controls: nil},
        %Evidence{id: "3", numeric_id: 3, name: "Evidence 3", nist_controls: ["SC-7"]}
      ]

      result = Workspace.get_evidence_by_controls(collection)

      assert result == %{
               "AC-1" => [
                 %Evidence{id: "1", numeric_id: 1, name: "Evidence 1", nist_controls: ["AC-1"]}
               ],
               "SC-7" => [
                 %Evidence{id: "3", numeric_id: 3, name: "Evidence 3", nist_controls: ["SC-7"]}
               ]
             }
    end

    test "filters out control IDs that don't match the NIST ID regex" do
      collection = [
        %Evidence{id: "1", numeric_id: 1, name: "Evidence 1", nist_controls: ["AC-1"]},
        %Evidence{id: "2", numeric_id: 2, name: "Evidence 2", nist_controls: ["invalid", "SC-7"]},
        %Evidence{id: "3", numeric_id: 3, name: "Evidence 3", nist_controls: ["not-a-control"]}
      ]

      result = Workspace.get_evidence_by_controls(collection)

      assert result == %{
               "AC-1" => [
                 %Evidence{id: "1", numeric_id: 1, name: "Evidence 1", nist_controls: ["AC-1"]}
               ],
               "SC-7" => [
                 %Evidence{
                   id: "2",
                   numeric_id: 2,
                   name: "Evidence 2",
                   nist_controls: ["invalid", "SC-7"]
                 }
               ]
             }
    end

    test "returns empty map when collection is empty" do
      assert Workspace.get_evidence_by_controls([]) == %{}
    end

    test "handles evidence with empty nist_controls array" do
      collection = [
        %Evidence{id: "1", numeric_id: 1, name: "Evidence 1", nist_controls: []},
        %Evidence{id: "2", numeric_id: 2, name: "Evidence 2", nist_controls: ["AC-1"]}
      ]

      result = Workspace.get_evidence_by_controls(collection)

      assert result == %{
               "AC-1" => [
                 %Evidence{id: "2", numeric_id: 2, name: "Evidence 2", nist_controls: ["AC-1"]}
               ]
             }
    end
  end
end
