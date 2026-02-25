defmodule ValentineWeb.Api.EvidenceControllerTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  describe "POST /api/evidence" do
    setup do
      workspace = workspace_fixture(%{name: "Test Workspace", owner: "test_owner"})
      api_key = api_key_fixture(%{workspace_id: workspace.id, owner: "test_owner"})

      %{workspace: workspace, api_key: api_key}
    end

    test "creates evidence with valid json_data attributes", %{conn: conn, api_key: api_key} do
      evidence_params = %{
        "name" => "Test Evidence",
        "description" => "Test description",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test content"},
        "nist_controls" => ["AC-1", "SC-7"],
        "tags" => ["security", "compliance"]
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      assert %{
               "evidence" => %{
                 "id" => _,
                 "name" => "Test Evidence",
                 "description" => "Test description",
                 "evidence_type" => "json_data",
                 "content" => %{"data" => "test content"},
                 "nist_controls" => ["AC-1", "SC-7"],
                 "tags" => ["security", "compliance"],
                 "workspace_id" => workspace_id,
                 "assumptions" => [],
                 "threats" => [],
                 "mitigations" => []
               },
               "message" => "Evidence created successfully"
             } = json_response(conn, 201)

      assert workspace_id == api_key.workspace_id
    end

    test "creates evidence with valid blob_store_link attributes", %{conn: conn, api_key: api_key} do
      evidence_params = %{
        "name" => "External Document",
        "description" => "External file evidence",
        "evidence_type" => "blob_store_link",
        "blob_store_url" => "https://example.com/document.pdf",
        "nist_controls" => ["AU-12"],
        "tags" => ["external"]
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      assert %{
               "evidence" => %{
                 "name" => "External Document",
                 "evidence_type" => "blob_store_link",
                 "blob_store_url" => "https://example.com/document.pdf",
                 "content" => nil,
                 "nist_controls" => ["AU-12"]
               }
             } = json_response(conn, 201)
    end

    test "links evidence to assumption when assumption_id is provided", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      assumption = assumption_fixture(%{workspace_id: workspace.id})

      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"}
      }

      linking_params = %{
        "assumption_id" => assumption.id
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      assert %{
               "evidence" => %{
                 "assumptions" => [%{"id" => assumption_id}]
               }
             } = json_response(conn, 201)

      assert assumption_id == assumption.id
    end

    test "links evidence to threat when threat_id is provided", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      threat = threat_fixture(%{workspace_id: workspace.id})

      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"}
      }

      linking_params = %{
        "threat_id" => threat.id
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      assert %{
               "evidence" => %{
                 "threats" => [%{"id" => threat_id}]
               }
             } = json_response(conn, 201)

      assert threat_id == threat.id
    end

    test "links evidence to mitigation when mitigation_id is provided", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"}
      }

      linking_params = %{
        "mitigation_id" => mitigation.id
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      assert %{
               "evidence" => %{
                 "mitigations" => [%{"id" => mitigation_id}]
               }
             } = json_response(conn, 201)

      assert mitigation_id == mitigation.id
    end

    test "links evidence to multiple entities when multiple IDs are provided", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      assumption = assumption_fixture(%{workspace_id: workspace.id})
      threat = threat_fixture(%{workspace_id: workspace.id})
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"}
      }

      linking_params = %{
        "assumption_id" => assumption.id,
        "threat_id" => threat.id,
        "mitigation_id" => mitigation.id
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      assert length(evidence_data["assumptions"]) == 1
      assert length(evidence_data["threats"]) == 1
      assert length(evidence_data["mitigations"]) == 1

      assert List.first(evidence_data["assumptions"])["id"] == assumption.id
      assert List.first(evidence_data["threats"])["id"] == threat.id
      assert List.first(evidence_data["mitigations"])["id"] == mitigation.id
    end

    test "ignores invalid entity IDs and continues with valid ones", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      assumption = assumption_fixture(%{workspace_id: workspace.id})
      invalid_uuid = "00000000-0000-0000-0000-000000000000"

      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"}
      }

      linking_params = %{
        "assumption_id" => assumption.id,
        # Invalid threat ID
        "threat_id" => invalid_uuid,
        # Invalid mitigation ID
        "mitigation_id" => invalid_uuid
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      # Should link to assumption but not to invalid entities
      assert length(evidence_data["assumptions"]) == 1
      assert length(evidence_data["threats"]) == 0
      assert length(evidence_data["mitigations"]) == 0

      assert List.first(evidence_data["assumptions"])["id"] == assumption.id
    end

    test "prevents linking to entities from different workspaces", %{conn: conn, api_key: api_key} do
      # Create entities in a different workspace
      other_workspace = workspace_fixture(%{name: "Other Workspace", owner: "other_owner"})
      other_assumption = assumption_fixture(%{workspace_id: other_workspace.id})

      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"}
      }

      linking_params = %{
        "assumption_id" => other_assumption.id
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      # Should not link to assumption from different workspace
      assert length(evidence_data["assumptions"]) == 0
    end

    test "accepts use_ai flag in linking parameters", %{conn: conn, api_key: api_key} do
      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"},
        "nist_controls" => ["AC-1"]
      }

      linking_params = %{
        "use_ai" => true
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      # Should create evidence successfully (AI functionality is stubbed)
      assert %{
               "evidence" => %{
                 "name" => "Test Evidence",
                 "nist_controls" => ["AC-1"]
               }
             } = json_response(conn, 201)
    end

    test "creates orphaned evidence when no linking parameters provided", %{
      conn: conn,
      api_key: api_key
    } do
      evidence_params = %{
        "name" => "Orphaned Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"},
        "nist_controls" => ["AC-1"]
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      assert %{
               "evidence" => %{
                 "name" => "Orphaned Evidence",
                 "assumptions" => [],
                 "threats" => [],
                 "mitigations" => []
               }
             } = json_response(conn, 201)
    end

    test "returns validation errors for invalid evidence attributes", %{
      conn: conn,
      api_key: api_key
    } do
      # Missing required fields
      evidence_params = %{
        "description" => "Missing name and evidence_type"
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      assert %{
               "errors" => errors
             } = json_response(conn, 422)

      assert Map.has_key?(errors, "name")
      assert Map.has_key?(errors, "evidence_type")
    end

    test "returns validation errors for invalid NIST controls", %{conn: conn, api_key: api_key} do
      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"},
        "nist_controls" => ["AC-1", "INVALID-ID"]
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      assert %{
               "errors" => %{
                 "nist_controls" => [error_message]
               }
             } = json_response(conn, 422)

      assert error_message =~ "contains invalid NIST control IDs"
    end

    test "returns validation errors for json_data without content", %{
      conn: conn,
      api_key: api_key
    } do
      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data"
        # Missing content field
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      assert %{
               "errors" => %{
                 "content" => [error_message]
               }
             } = json_response(conn, 422)

      assert error_message =~ "must be provided when evidence_type is JSON Content"
    end

    test "returns validation errors for blob_store_link without blob_store_url", %{
      conn: conn,
      api_key: api_key
    } do
      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "blob_store_link"
        # Missing blob_store_url field
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      assert %{
               "errors" => %{
                 "blob_store_url" => [error_message]
               }
             } = json_response(conn, 422)

      assert error_message =~ "must be provided when evidence_type is File Link"
    end

    test "links evidence to entities based on NIST control overlap", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      # Create entities with NIST controls in their tags
      assumption =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls are implemented",
          tags: ["AC-1", "security", "access-control"]
        })

      threat =
        threat_fixture(%{
          workspace_id: workspace.id,
          threat_action: "Unauthorized access",
          tags: ["AU-12", "logging", "monitoring"]
        })

      mitigation =
        mitigation_fixture(%{
          workspace_id: workspace.id,
          content: "Implement proper access controls",
          tags: ["AC-1", "AU-12", "controls"]
        })

      # Create evidence with NIST controls that overlap with entity tags
      evidence_params = %{
        "name" => "NIST Control Evidence",
        "evidence_type" => "json_data",
        "content" => %{"audit_findings" => "AC-1 and AU-12 controls verified"},
        "nist_controls" => ["AC-1", "AU-12"]
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      # Should link to assumption (has AC-1 tag)
      assert length(evidence_data["assumptions"]) == 1
      assert List.first(evidence_data["assumptions"])["id"] == assumption.id

      # Should link to threat (has AU-12 tag)  
      assert length(evidence_data["threats"]) == 1
      assert List.first(evidence_data["threats"])["id"] == threat.id

      # Should link to mitigation (has both AC-1 and AU-12 tags)
      assert length(evidence_data["mitigations"]) == 1
      assert List.first(evidence_data["mitigations"])["id"] == mitigation.id
    end

    test "NIST control linking only works within same workspace", %{conn: conn, api_key: api_key} do
      # Create entities in different workspace
      other_workspace = workspace_fixture(%{name: "Other Workspace", owner: "other_owner"})

      _other_assumption =
        assumption_fixture(%{
          workspace_id: other_workspace.id,
          content: "Access controls in other workspace",
          tags: ["AC-1", "security"]
        })

      # Create evidence with NIST controls
      evidence_params = %{
        "name" => "NIST Control Evidence",
        "evidence_type" => "json_data",
        "content" => %{"audit_findings" => "AC-1 controls verified"},
        "nist_controls" => ["AC-1"]
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      # Should not link to entities from other workspace
      assert length(evidence_data["assumptions"]) == 0
      assert length(evidence_data["threats"]) == 0
      assert length(evidence_data["mitigations"]) == 0
    end

    test "direct ID linking takes precedence over NIST control linking", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      # Create entity with tags that would match NIST controls
      _assumption_with_tags =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls assumption",
          tags: ["AC-1", "security"]
        })

      # Create different entity for direct linking
      assumption_for_direct_link =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Different assumption",
          # No overlap with evidence NIST controls
          tags: ["SC-7", "network"]
        })

      evidence_params = %{
        "name" => "Test Evidence",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"},
        # Would match assumption_with_tags
        "nist_controls" => ["AC-1"]
      }

      linking_params = %{
        # Direct link to different entity
        "assumption_id" => assumption_for_direct_link.id
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")

      conn =
        post(conn, ~p"/api/evidence", %{
          "evidence" => evidence_params,
          "linking" => linking_params
        })

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      # Should only link to directly specified entity, not NIST control matches
      assert length(evidence_data["assumptions"]) == 1
      assert List.first(evidence_data["assumptions"])["id"] == assumption_for_direct_link.id
      # Should NOT link to assumption_with_tags despite NIST control overlap
    end

    test "creates evidence without linking when no NIST controls provided", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      # Create entity with tags
      _assumption =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls assumption",
          tags: ["AC-1", "security"]
        })

      evidence_params = %{
        "name" => "Evidence Without NIST Controls",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"}
        # No nist_controls field
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      # Should not link to any entities
      assert length(evidence_data["assumptions"]) == 0
      assert length(evidence_data["threats"]) == 0
      assert length(evidence_data["mitigations"]) == 0
    end

    test "creates evidence without linking when empty NIST controls provided", %{
      conn: conn,
      api_key: api_key,
      workspace: workspace
    } do
      # Create entity with tags
      _assumption =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls assumption",
          tags: ["AC-1", "security"]
        })

      evidence_params = %{
        "name" => "Evidence With Empty NIST Controls",
        "evidence_type" => "json_data",
        "content" => %{"data" => "test"},
        # Empty array
        "nist_controls" => []
      }

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      conn = post(conn, ~p"/api/evidence", %{"evidence" => evidence_params})

      response = json_response(conn, 201)
      evidence_data = response["evidence"]

      # Should not link to any entities
      assert length(evidence_data["assumptions"]) == 0
      assert length(evidence_data["threats"]) == 0
      assert length(evidence_data["mitigations"]) == 0
    end
  end
end
