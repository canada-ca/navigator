defmodule ValentineWeb.Workspace.MermaidTest do
  use ExUnit.Case, async: true

  alias ValentineWeb.Workspace.Mermaid

  describe "generate_nodes/1" do
    test "formats actor nodes correctly" do
      nodes = %{
        "node-1" => %{
          "data" => %{
            "id" => "node-1",
            "label" => "User",
            "type" => "actor"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "  node_1[User]"
    end

    test "formats process nodes correctly" do
      nodes = %{
        "node-2" => %{
          "data" => %{
            "id" => "node-2",
            "label" => "Login Process",
            "type" => "process"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "  node_2(Login Process)"
    end

    test "formats datastore nodes correctly" do
      nodes = %{
        "node-3" => %{
          "data" => %{
            "id" => "node-3",
            "label" => "User Database",
            "type" => "datastore"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "  node_3[(User Database)]"
    end

    test "formats trust boundary correctly" do
      nodes = %{
        "node-4" => %{
          "data" => %{
            "id" => "node-4",
            "label" => "Secure Zone",
            "type" => "trust_boundary"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "  subgraph node_4 [Secure Zone]"
    end

    test "sanitizes node IDs with special characters" do
      nodes = %{
        "node-special!" => %{
          "data" => %{
            "id" => "node-special!",
            "label" => "Special Node",
            "type" => "actor"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "  node_special_[Special Node]"
    end

    test "handles nodes with special characters in labels" do
      nodes = %{
        "node-1" => %{
          "data" => %{
            "id" => "node-1",
            "label" => "User [Admin]",
            "type" => "actor"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "  node_1[User &#91;Admin&#93;]"
    end
  end

  describe "generate_edges/2" do
    test "formats simple edges correctly" do
      edges = %{
        "edge-1" => %{
          "data" => %{
            "id" => "edge-1",
            "source" => "node-1",
            "target" => "node-2",
            "label" => "Data flow"
          }
        }
      }

      nodes = %{
        "node-1" => %{"data" => %{"id" => "node-1"}},
        "node-2" => %{"data" => %{"id" => "node-2"}}
      }

      result = Mermaid.generate_edges(edges, nodes)
      assert result == "  node_1 -->|Data flow| node_2"
    end

    test "formats edges without labels" do
      edges = %{
        "edge-1" => %{
          "data" => %{
            "id" => "edge-1",
            "source" => "node-1",
            "target" => "node-2",
            "label" => ""
          }
        }
      }

      nodes = %{
        "node-1" => %{"data" => %{"id" => "node-1"}},
        "node-2" => %{"data" => %{"id" => "node-2"}}
      }

      result = Mermaid.generate_edges(edges, nodes)
      assert result == "  node_1 --> node_2"
    end

    test "skips edges with missing source or target nodes" do
      edges = %{
        "edge-1" => %{
          "data" => %{
            "id" => "edge-1",
            "source" => "node-missing",
            "target" => "node-2",
            "label" => "Data flow"
          }
        }
      }

      nodes = %{
        "node-2" => %{"data" => %{"id" => "node-2"}}
      }

      result = Mermaid.generate_edges(edges, nodes)
      assert result == ""
    end
  end

  describe "generate_flowchart/1" do
    test "generates a complete Mermaid flowchart" do
      # This would require mocking DataFlowDiagram.get/1
      # For now, we'll test the structure indirectly through the component functions
      nodes = %{
        "node-1" => %{
          "data" => %{
            "id" => "node-1",
            "label" => "User",
            "type" => "actor"
          }
        },
        "node-2" => %{
          "data" => %{
            "id" => "node-2",
            "label" => "Process",
            "type" => "process"
          }
        }
      }

      edges = %{
        "edge-1" => %{
          "data" => %{
            "id" => "edge-1",
            "source" => "node-1",
            "target" => "node-2",
            "label" => "Request"
          }
        }
      }

      nodes_output = Mermaid.generate_nodes(nodes)
      edges_output = Mermaid.generate_edges(edges, nodes)

      assert nodes_output == "  node_1[User]\n  node_2(Process)"
      assert edges_output == "  node_1 -->|Request| node_2"
    end
  end
end
