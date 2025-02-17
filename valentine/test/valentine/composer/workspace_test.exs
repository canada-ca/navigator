defmodule Valentine.Composer.WorkspaceTest do
  use ValentineWeb.ConnCase

  alias Valentine.Composer.Workspace
  alias Valentine.Composer.Assumption
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.Threat

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
end
