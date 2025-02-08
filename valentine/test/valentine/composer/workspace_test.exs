defmodule Valentine.Composer.WorkspaceTest do
  use ValentineWeb.ConnCase

  alias Valentine.Composer.Workspace
  alias Valentine.Composer.Assumption
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.Threat

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
