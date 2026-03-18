defmodule ValentineWeb.Workspace.Mermaid.ImportTest do
  use ExUnit.Case, async: true

  alias ValentineWeb.Workspace.Mermaid.Import

  describe "preview/1" do
    test "imports canonical stateDiagram-v2 output" do
      mermaid = """
      stateDiagram-v2
          node_1 : External User
          state GitHub {
              node_2 : Authentication Service
              node_3 : Public repositories
          }
          node_1 --> node_2 : Login
          node_2 --> node_3 : Read repository
      """

      assert {:ok, preview} = Import.preview(mermaid)

      assert preview.summary.nodes == 4
      assert preview.summary.edges == 2
      assert preview.summary.trust_boundaries == 1

      assert preview.nodes["node_1"]["data"]["label"] == "External User"
      assert preview.nodes["node_2"]["data"]["parent"] != nil
      assert preview.nodes["node_3"]["data"]["type"] == "datastore"

      assert Enum.any?(preview.warnings, &(&1.code == :metadata_defaults))
      assert Enum.any?(preview.warnings, &(&1.code == :inferred_node_type))
    end

    test "imports legacy stateDiagram syntax" do
      mermaid = """
      stateDiagram
          User : User
          API : API Gateway
          User --> API : Request
      """

      assert {:ok, preview} = Import.preview(mermaid)

      assert preview.summary.nodes == 2
      assert preview.summary.edges == 1
      assert Enum.all?(Map.keys(preview.nodes), &String.starts_with?(&1, "node"))
    end

    test "imports supported flowchart syntax and subgraphs" do
      mermaid = """
      flowchart LR
          ext[External User] -->|Request| auth[Auth Service]
          subgraph GitHub
              auth --> repo[(Repository Storage)]
          end
      """

      assert {:ok, preview} = Import.preview(mermaid)

      assert preview.summary.nodes == 4
      assert preview.summary.edges == 2
      assert preview.summary.trust_boundaries == 1

      repo_node =
        preview.nodes
        |> Map.values()
        |> Enum.find(&(&1["data"]["label"] == "Repository Storage"))

      assert repo_node["data"]["type"] == "datastore"
      assert Enum.any?(preview.warnings, &(&1.code == :implicit_boundary))
    end

    test "reports unsupported directives as warnings" do
      mermaid = """
      stateDiagram-v2
          node_1 : User
          style node_1 fill:#fff
      """

      assert {:ok, preview} = Import.preview(mermaid)

      assert Enum.any?(preview.warnings, &(&1.code == :unsupported_construct))
    end

    test "rejects unsupported diagram headers" do
      mermaid = """
      sequenceDiagram
          Alice->>Bob: Hello
      """

      assert {:error, "Unsupported Mermaid diagram type"} = Import.preview(mermaid)
    end

    test "rejects invalid Mermaid syntax" do
      mermaid = """
      flowchart LR
          A -->
      """

      assert {:error, "Unsupported Mermaid flowchart syntax"} = Import.preview(mermaid)
    end

    test "rejects nested groups that are outside the supported subset" do
      mermaid = """
      stateDiagram-v2
          state Outer {
              state Inner {
                  node_1 : User
              }
          }
      """

      assert {:error, "Nested Mermaid state groups are not supported"} = Import.preview(mermaid)
    end

    test "applies navigator defaults to imported elements" do
      mermaid = """
      stateDiagram-v2
          node_1 : External User
      """

      assert {:ok, preview} = Import.preview(mermaid)
      node = preview.nodes["node_1"]

      assert node["data"]["description"] == nil
      assert node["data"]["data_tags"] == []
      assert node["data"]["linked_threats"] == []
      assert node["data"]["out_of_scope"] == "false"
      assert is_map(node["position"])
    end
  end
end
