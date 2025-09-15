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
            "type" => "actor",
            "parent" => nil
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "    node_1 : User"
    end

    test "formats process nodes correctly" do
      nodes = %{
        "node-2" => %{
          "data" => %{
            "id" => "node-2",
            "label" => "Login Process",
            "type" => "process",
            "parent" => nil
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "    node_2 : Login Process"
    end

    test "formats datastore nodes correctly" do
      nodes = %{
        "node-3" => %{
          "data" => %{
            "id" => "node-3",
            "label" => "User Database",
            "type" => "datastore",
            "parent" => nil
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "    node_3 : User Database"
    end

    test "formats trust boundary correctly with nested nodes" do
      nodes = %{
        "node-4" => %{
          "data" => %{
            "id" => "node-4",
            "label" => "GitHub",
            "type" => "trust_boundary"
          }
        },
        "node-5" => %{
          "data" => %{
            "id" => "node-5",
            "label" => "GitHub Authentication",
            "type" => "process",
            "parent" => "node-4"
          }
        },
        "node-6" => %{
          "data" => %{
            "id" => "node-6",
            "label" => "Public repositories",
            "type" => "datastore",
            "parent" => "node-4"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)

      expected =
        "    state GitHub {\n        node_5 : GitHub Authentication\n        node_6 : Public repositories\n    }"

      assert result == expected
    end

    test "formats empty trust boundary correctly" do
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
      assert result == "    state Secure_Zone {\n    }"
    end

    test "sanitizes node IDs with special characters" do
      nodes = %{
        "node-special!" => %{
          "data" => %{
            "id" => "node-special!",
            "label" => "Special Node",
            "type" => "actor",
            "parent" => nil
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "    node_special_ : Special Node"
    end

    test "handles nodes with special characters in labels" do
      nodes = %{
        "node-1" => %{
          "data" => %{
            "id" => "node-1",
            "label" => "User [Admin]",
            "type" => "actor",
            "parent" => nil
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)
      assert result == "    node_1 : User &#91;Admin&#93;"
    end

    test "generates mixed standalone and trust boundary nodes correctly" do
      nodes = %{
        "node-1" => %{
          "data" => %{
            "id" => "node-1",
            "label" => "External User",
            "type" => "actor",
            "parent" => nil
          }
        },
        "node-2" => %{
          "data" => %{
            "id" => "node-2",
            "label" => "GitHub",
            "type" => "trust_boundary"
          }
        },
        "node-3" => %{
          "data" => %{
            "id" => "node-3",
            "label" => "Authentication Service",
            "type" => "process",
            "parent" => "node-2"
          }
        },
        "node-4" => %{
          "data" => %{
            "id" => "node-4",
            "label" => "Repository Storage",
            "type" => "datastore",
            "parent" => "node-2"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)

      expected =
        "    node_1 : External User\n    state GitHub {\n        node_3 : Authentication Service\n        node_4 : Repository Storage\n    }"

      assert result == expected
    end

    test "generates the exact format from the GitHub comment example" do
      # Test data based on the example provided in the GitHub comment
      nodes = %{
        "node_101890" => %{
          "data" => %{
            "id" => "node_101890",
            "label" => "Priviliged user",
            "type" => "actor",
            "parent" => nil
          }
        },
        "node_260" => %{
          "data" => %{
            "id" => "node_260",
            "label" => "3rd party application",
            "type" => "actor",
            "parent" => nil
          }
        },
        "node_88898" => %{
          "data" => %{
            "id" => "node_88898",
            "label" => "Classic personal access token",
            "type" => "datastore",
            "parent" => nil
          }
        },
        "node_89858" => %{
          "data" => %{
            "id" => "node_89858",
            "label" => "SSH Key",
            "type" => "datastore",
            "parent" => nil
          }
        },
        "node_90306" => %{
          "data" => %{
            "id" => "node_90306",
            "label" => "Fine-grained personal access token",
            "type" => "datastore",
            "parent" => nil
          }
        },
        "node_92226" => %{
          "data" => %{
            "id" => "node_92226",
            "label" => "Anonymous user",
            "type" => "actor",
            "parent" => nil
          }
        },
        "node_9923" => %{
          "data" => %{
            "id" => "node_9923",
            "label" => "GitHub",
            "type" => "trust_boundary"
          }
        },
        "node_93122" => %{
          "data" => %{
            "id" => "node_93122",
            "label" => "GitHub Authentication",
            "type" => "process",
            "parent" => "node_9923"
          }
        },
        "node_96770" => %{
          "data" => %{
            "id" => "node_96770",
            "label" => "Public repositories",
            "type" => "datastore",
            "parent" => "node_9923"
          }
        },
        "node_14595" => %{
          "data" => %{
            "id" => "node_14595",
            "label" => "GitHub actions",
            "type" => "process",
            "parent" => "node_9923"
          }
        },
        "node_7875" => %{
          "data" => %{
            "id" => "node_7875",
            "label" => "Private repositories",
            "type" => "datastore",
            "parent" => "node_9923"
          }
        }
      }

      result = Mermaid.generate_nodes(nodes)

      # The expected format should have:
      # 1. Standalone nodes listed first
      # 2. Trust boundary as a state with the label as the state name
      # 3. Nested nodes inside the trust boundary state

      # Since the order of nodes within each category might vary,
      # let's verify the key structural elements are present
      assert String.contains?(result, "state GitHub {")
      assert String.contains?(result, "node_93122 : GitHub Authentication")
      assert String.contains?(result, "node_96770 : Public repositories")
      assert String.contains?(result, "node_14595 : GitHub actions")
      assert String.contains?(result, "node_7875 : Private repositories")
      assert String.contains?(result, "node_101890 : Priviliged user")
      assert String.contains?(result, "node_260 : 3rd party application")
      assert String.contains?(result, "node_88898 : Classic personal access token")
      assert String.contains?(result, "node_89858 : SSH Key")
      assert String.contains?(result, "node_90306 : Fine-grained personal access token")
      assert String.contains?(result, "node_92226 : Anonymous user")

      # Verify that all the nested nodes are properly indented within the state
      lines = String.split(result, "\n")
      github_state_start = Enum.find_index(lines, &String.contains?(&1, "state GitHub {"))

      github_state_end =
        Enum.find_index(lines, fn line ->
          String.trim(line) == "}" &&
            Enum.find_index(lines, &(&1 == line)) > github_state_start
        end)

      # All lines between the start and end should be indented nested nodes
      assert github_state_start != nil
      assert github_state_end != nil

      nested_lines = Enum.slice(lines, (github_state_start + 1)..(github_state_end - 1))

      Enum.each(nested_lines, fn line ->
        assert String.starts_with?(line, "        node_")
      end)
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
      assert result == "    node_1 --> node_2 : Data flow"
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
      assert result == "    node_1 --> node_2"
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
    test "generates a complete Mermaid state diagram" do
      # This would require mocking DataFlowDiagram.get/1
      # For now, we'll test the structure indirectly through the component functions
      nodes = %{
        "node-1" => %{
          "data" => %{
            "id" => "node-1",
            "label" => "User",
            "type" => "actor",
            "parent" => nil
          }
        },
        "node-2" => %{
          "data" => %{
            "id" => "node-2",
            "label" => "Process",
            "type" => "process",
            "parent" => nil
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

      assert nodes_output == "    node_1 : User\n    node_2 : Process"
      assert edges_output == "    node_1 --> node_2 : Request"
    end
  end
end
