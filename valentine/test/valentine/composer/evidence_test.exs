defmodule Valentine.Composer.EvidenceTest do
  use Valentine.DataCase

  alias Valentine.Composer
  alias Valentine.Composer.Evidence

  import Valentine.ComposerFixtures

  describe "evidence" do
    test "list_evidence/1 returns all evidence for a workspace" do
      workspace = workspace_fixture()
      evidence1 = evidence_fixture(%{workspace_id: workspace.id})
      evidence2 = evidence_fixture(%{workspace_id: workspace.id, name: "another evidence"})
      other_workspace = workspace_fixture()
      _other_evidence = evidence_fixture(%{workspace_id: other_workspace.id})

      evidence_list = Composer.list_evidence(workspace.id)
      assert length(evidence_list) == 2
      assert Enum.any?(evidence_list, fn e -> e.id == evidence1.id end)
      assert Enum.any?(evidence_list, fn e -> e.id == evidence2.id end)
    end

    test "get_evidence!/1 returns the evidence with given id" do
      evidence = evidence_fixture()
      assert Composer.get_evidence!(evidence.id).id == evidence.id
    end

    test "create_evidence/1 with valid json_data creates evidence" do
      workspace = workspace_fixture()

      valid_attrs = %{
        workspace_id: workspace.id,
        name: "Test Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"document_type" => "OSCAL", "data" => "test data"},
        nist_controls: ["AC-1", "SC-7"],
        tags: ["security", "compliance"]
      }

      assert {:ok, %Evidence{} = evidence} = Composer.create_evidence(valid_attrs)
      assert evidence.name == "Test Evidence"
      assert evidence.description == "Test description"
      assert evidence.evidence_type == :json_data
      assert evidence.content == %{"document_type" => "OSCAL", "data" => "test data"}
      assert evidence.blob_store_url == nil
      assert evidence.nist_controls == ["AC-1", "SC-7"]
      assert evidence.tags == ["security", "compliance"]
      assert evidence.numeric_id == 1
    end

    test "create_evidence/1 with valid blob_store_link creates evidence" do
      workspace = workspace_fixture()

      valid_attrs = %{
        workspace_id: workspace.id,
        name: "External Document",
        description: "External file evidence",
        evidence_type: :blob_store_link,
        blob_store_url: "https://example.com/document.pdf",
        nist_controls: ["AU-12"],
        tags: ["external"]
      }

      assert {:ok, %Evidence{} = evidence} = Composer.create_evidence(valid_attrs)
      assert evidence.name == "External Document"
      assert evidence.evidence_type == :blob_store_link
      assert evidence.blob_store_url == "https://example.com/document.pdf"
      assert evidence.content == nil
      assert evidence.nist_controls == ["AU-12"]
      assert evidence.numeric_id == 1
    end

    test "create_evidence/1 with invalid json_data type returns error changeset" do
      workspace = workspace_fixture()

      invalid_attrs = %{
        workspace_id: workspace.id,
        name: "Test Evidence",
        description: "Test description",
        evidence_type: :json_data,
        # Missing content for json_data type
        blob_store_url: "https://example.com/doc.pdf"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(invalid_attrs)
      assert "must be provided for this evidence type" in errors_on(changeset).content
    end

    test "create_evidence/1 with invalid blob_store_link type returns error changeset" do
      workspace = workspace_fixture()

      invalid_attrs = %{
        workspace_id: workspace.id,
        name: "Test Evidence",
        description: "Test description",
        evidence_type: :blob_store_link,
        # Missing blob_store_url for blob_store_link type
        content: %{"data" => "some data"}
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(invalid_attrs)

      assert "must be provided for this evidence type" in errors_on(changeset).blob_store_url
    end

    test "create_evidence/1 with valid blob_store_link URLs with various schemes succeeds" do
      workspace = workspace_fixture()

      valid_urls = [
        "https://example.com/document.pdf",
        "http://example.com/file.txt",
        "s3://my-bucket/path/to/file.zip",
        "gs://bucket/object",
        "ftp://ftp.example.com/file.tar.gz"
      ]

      for url <- valid_urls do
        attrs = %{
          workspace_id: workspace.id,
          name: "Evidence with #{URI.parse(url).scheme} URL",
          description: "Test evidence with #{URI.parse(url).scheme} URL scheme",
          evidence_type: :blob_store_link,
          blob_store_url: url
        }

        assert {:ok, %Evidence{} = evidence} = Composer.create_evidence(attrs)
        assert evidence.blob_store_url == url
      end
    end

    test "create_evidence/1 with blob_store_link URL without scheme returns error" do
      workspace = workspace_fixture()

      invalid_urls = [
        "example.com/document.pdf",
        "//example.com/file",
        "/absolute/path",
        "relative/path"
      ]

      for url <- invalid_urls do
        attrs = %{
          workspace_id: workspace.id,
          name: "Invalid Evidence",
          description: "Test description",
          evidence_type: :blob_store_link,
          blob_store_url: url
        }

        assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(attrs)

        assert "must be a valid URL with a scheme (e.g., https://example.com)" in errors_on(
                 changeset
               ).blob_store_url
      end
    end

    test "create_evidence/1 with blob_store_link malformed URL returns error" do
      workspace = workspace_fixture()

      malformed_urls = [
        "ht!tp://bad url with spaces",
        "not a url at all",
        "https://[invalid",
        "just plain text"
      ]

      for url <- malformed_urls do
        attrs = %{
          workspace_id: workspace.id,
          name: "Malformed Evidence",
          description: "Test description",
          evidence_type: :blob_store_link,
          blob_store_url: url
        }

        assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(attrs)
        errors = errors_on(changeset).blob_store_url
        assert Enum.any?(errors, fn error -> String.contains?(error, "must be a valid URL") end)
      end
    end

    test "create_evidence/1 with blob_store_link URL without host returns error" do
      workspace = workspace_fixture()

      urls_without_host = [
        "https://",
        "http://",
        "s3://",
        "ftp://"
      ]

      for url <- urls_without_host do
        attrs = %{
          workspace_id: workspace.id,
          name: "Invalid Evidence",
          description: "Test description",
          evidence_type: :blob_store_link,
          blob_store_url: url
        }

        assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(attrs)

        assert "must include a host (e.g., https://example.com)" in errors_on(changeset).blob_store_url
      end
    end

    test "create_evidence/1 with blob_store_link using disallowed schemes returns error" do
      workspace = workspace_fixture()

      dangerous_urls = [
        "javascript:alert(1)",
        "data:text/html,<script>alert(1)</script>",
        "file:///etc/passwd",
        "vbscript:msgbox(1)",
        "about:blank"
      ]

      for url <- dangerous_urls do
        attrs = %{
          workspace_id: workspace.id,
          name: "Dangerous Evidence",
          description: "Test description",
          evidence_type: :blob_store_link,
          blob_store_url: url
        }

        assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(attrs)

        # Some URLs fail parsing entirely, others fail scheme validation
        # Both are acceptable rejections for security purposes
        errors = errors_on(changeset).blob_store_url

        assert Enum.any?(errors, fn error ->
                 String.contains?(error, "must use an allowed URL scheme") or
                   String.contains?(error, "must be a valid URL")
               end)
      end
    end

    test "create_evidence/1 with json_data type ignores blob_store_url validation" do
      workspace = workspace_fixture()

      # Even with an invalid URL, json_data evidence should succeed
      # because blob_store_url is cleared for json_data type
      attrs = %{
        workspace_id: workspace.id,
        name: "JSON Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test content"},
        blob_store_url: "not a valid url"
      }

      assert {:ok, %Evidence{} = evidence} = Composer.create_evidence(attrs)
      assert evidence.evidence_type == :json_data
      assert evidence.content == %{"data" => "test content"}
      # blob_store_url should be cleared for json_data type
      assert is_nil(evidence.blob_store_url)
    end

    test "create_evidence/1 with valid description_only creates evidence" do
      workspace = workspace_fixture()

      valid_attrs = %{
        workspace_id: workspace.id,
        name: "Description Only Evidence",
        description: "This evidence only has a description, no attachments",
        evidence_type: :description_only,
        nist_controls: ["AC-2"],
        tags: ["policy"]
      }

      assert {:ok, %Evidence{} = evidence} = Composer.create_evidence(valid_attrs)
      assert evidence.name == "Description Only Evidence"
      assert evidence.description == "This evidence only has a description, no attachments"
      assert evidence.evidence_type == :description_only
      assert evidence.content == nil
      assert evidence.blob_store_url == nil
      assert evidence.nist_controls == ["AC-2"]
      assert evidence.tags == ["policy"]
      assert evidence.numeric_id == 1
    end

    test "create_evidence/1 with description_only and attachment fields fails validation" do
      workspace = workspace_fixture()

      # Test with content field
      invalid_attrs_content = %{
        workspace_id: workspace.id,
        name: "Invalid Evidence",
        description: "Description",
        evidence_type: :description_only,
        content: %{"data" => "should not be here"}
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Composer.create_evidence(invalid_attrs_content)

      assert "description_only evidence cannot have content or blob_store_url" in errors_on(
               changeset
             ).evidence_type

      # Test with blob_store_url field
      invalid_attrs_url = %{
        workspace_id: workspace.id,
        name: "Invalid Evidence",
        description: "Description",
        evidence_type: :description_only,
        blob_store_url: "https://example.com/file.pdf"
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Composer.create_evidence(invalid_attrs_url)

      assert "description_only evidence cannot have content or blob_store_url" in errors_on(
               changeset
             ).evidence_type
    end

    test "create_evidence/1 without description fails validation for all types" do
      workspace = workspace_fixture()

      # Test description_only without description
      assert {:error, %Ecto.Changeset{} = changeset} =
               Composer.create_evidence(%{
                 workspace_id: workspace.id,
                 name: "No Description",
                 evidence_type: :description_only
               })

      assert "can't be blank" in errors_on(changeset).description

      # Test json_data without description
      assert {:error, %Ecto.Changeset{} = changeset} =
               Composer.create_evidence(%{
                 workspace_id: workspace.id,
                 name: "No Description",
                 evidence_type: :json_data,
                 content: %{"data" => "test"}
               })

      assert "can't be blank" in errors_on(changeset).description

      # Test blob_store_link without description
      assert {:error, %Ecto.Changeset{} = changeset} =
               Composer.create_evidence(%{
                 workspace_id: workspace.id,
                 name: "No Description",
                 evidence_type: :blob_store_link,
                 blob_store_url: "https://example.com/file.pdf"
               })

      assert "can't be blank" in errors_on(changeset).description
    end

    test "create_evidence/1 with existing types still works correctly" do
      workspace = workspace_fixture()

      # Test json_data still works
      {:ok, json_evidence} =
        Composer.create_evidence(%{
          workspace_id: workspace.id,
          name: "JSON Test",
          description: "JSON description",
          evidence_type: :json_data,
          content: %{"data" => "test"}
        })

      assert json_evidence.evidence_type == :json_data
      assert json_evidence.content == %{"data" => "test"}
      assert json_evidence.blob_store_url == nil

      # Test blob_store_link still works
      {:ok, link_evidence} =
        Composer.create_evidence(%{
          workspace_id: workspace.id,
          name: "Link Test",
          description: "Link description",
          evidence_type: :blob_store_link,
          blob_store_url: "https://example.com/file.pdf"
        })

      assert link_evidence.evidence_type == :blob_store_link
      assert link_evidence.blob_store_url == "https://example.com/file.pdf"
      assert link_evidence.content == nil
    end

    test "update_evidence/2 with invalid blob_store_link URL returns error" do
      workspace = workspace_fixture()

      # Create valid evidence first
      {:ok, evidence} =
        Composer.create_evidence(%{
          workspace_id: workspace.id,
          name: "Valid Evidence",
          description: "Test description",
          evidence_type: :blob_store_link,
          blob_store_url: "https://example.com/original.pdf"
        })

      # Try to update with invalid URL
      invalid_update = %{blob_store_url: "example.com/no-scheme.pdf"}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Composer.update_evidence(evidence, invalid_update)

      assert "must be a valid URL with a scheme (e.g., https://example.com)" in errors_on(
               changeset
             ).blob_store_url
    end

    test "create_evidence/1 with invalid NIST controls returns error changeset" do
      workspace = workspace_fixture()

      invalid_attrs = %{
        workspace_id: workspace.id,
        name: "Test Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test"},
        nist_controls: ["AC-1", "INVALID-ID", "SC-7.4"]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(invalid_attrs)
      assert "contains invalid NIST control IDs: INVALID-ID" in errors_on(changeset).nist_controls
    end

    test "create_evidence/1 with valid NIST controls succeeds" do
      workspace = workspace_fixture()

      valid_attrs = %{
        workspace_id: workspace.id,
        name: "Test Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test"},
        nist_controls: ["AC-1", "SC-7.4", "AU-12", "IA-2.1"]
      }

      assert {:ok, %Evidence{} = evidence} = Composer.create_evidence(valid_attrs)
      assert evidence.nist_controls == ["AC-1", "SC-7.4", "AU-12", "IA-2.1"]
    end

    test "create_evidence/1 without required fields returns error changeset" do
      invalid_attrs = %{}

      assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(invalid_attrs)
      assert "can't be blank" in errors_on(changeset).workspace_id
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).evidence_type
    end

    test "update_evidence/2 with valid data updates the evidence" do
      evidence = evidence_fixture()

      update_attrs = %{
        name: "Updated Evidence",
        description: "Updated description",
        nist_controls: ["IA-5"],
        tags: ["updated"]
      }

      assert {:ok, %Evidence{} = evidence} = Composer.update_evidence(evidence, update_attrs)
      assert evidence.name == "Updated Evidence"
      assert evidence.description == "Updated description"
      assert evidence.nist_controls == ["IA-5"]
      assert evidence.tags == ["updated"]
    end

    test "update_evidence/2 with invalid data returns error changeset" do
      evidence = evidence_fixture()

      assert {:error, %Ecto.Changeset{}} = Composer.update_evidence(evidence, %{name: nil})
      assert evidence == Composer.get_evidence!(evidence.id)
    end

    test "delete_evidence/1 deletes the evidence" do
      evidence = evidence_fixture()
      assert {:ok, %Evidence{}} = Composer.delete_evidence(evidence)
      assert_raise Ecto.NoResultsError, fn -> Composer.get_evidence!(evidence.id) end
    end

    test "change_evidence/1 returns an evidence changeset" do
      evidence = evidence_fixture()
      assert %Ecto.Changeset{} = Composer.change_evidence(evidence)
    end

    test "numeric_id is auto-incremented within workspace" do
      workspace = workspace_fixture()

      {:ok, evidence1} =
        Composer.create_evidence(%{
          workspace_id: workspace.id,
          name: "Evidence 1",
          description: "Test description",
          evidence_type: :json_data,
          content: %{"data" => "test1"}
        })

      {:ok, evidence2} =
        Composer.create_evidence(%{
          workspace_id: workspace.id,
          name: "Evidence 2",
          description: "Test description",
          evidence_type: :json_data,
          content: %{"data" => "test2"}
        })

      # Different workspace should start from 1 again
      other_workspace = workspace_fixture()

      {:ok, evidence3} =
        Composer.create_evidence(%{
          workspace_id: other_workspace.id,
          name: "Evidence 3",
          description: "Test description",
          evidence_type: :json_data,
          content: %{"data" => "test3"}
        })

      assert evidence1.numeric_id == 1
      assert evidence2.numeric_id == 2
      assert evidence3.numeric_id == 1
    end
  end

  describe "evidence relationships" do
    test "evidence can be associated with assumptions" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      assumption = assumption_fixture(%{workspace_id: workspace.id})

      # Load evidence with associations
      evidence = Valentine.Repo.preload(evidence, [:assumptions, :evidence_assumptions])

      # Initially no associations
      assert evidence.assumptions == []

      # Create association through join table
      {:ok, _join} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceAssumption{
          evidence_id: evidence.id,
          assumption_id: assumption.id
        })

      # Reload and verify association
      evidence = Valentine.Repo.preload(Composer.get_evidence!(evidence.id), :assumptions)
      assert length(evidence.assumptions) == 1
      assert List.first(evidence.assumptions).id == assumption.id
    end

    test "evidence can be associated with threats" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      threat = threat_fixture(%{workspace_id: workspace.id})

      # Load evidence with associations
      evidence = Valentine.Repo.preload(evidence, [:threats, :evidence_threats])

      # Initially no associations
      assert evidence.threats == []

      # Create association through join table
      {:ok, _join} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceThreat{
          evidence_id: evidence.id,
          threat_id: threat.id
        })

      # Reload and verify association
      evidence = Valentine.Repo.preload(Composer.get_evidence!(evidence.id), :threats)
      assert length(evidence.threats) == 1
      assert List.first(evidence.threats).id == threat.id
    end

    test "evidence can be associated with mitigations" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      # Load evidence with associations
      evidence = Valentine.Repo.preload(evidence, [:mitigations, :evidence_mitigations])

      # Initially no associations
      assert evidence.mitigations == []

      # Create association through join table
      {:ok, _join} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceMitigation{
          evidence_id: evidence.id,
          mitigation_id: mitigation.id
        })

      # Reload and verify association
      evidence = Valentine.Repo.preload(Composer.get_evidence!(evidence.id), :mitigations)
      assert length(evidence.mitigations) == 1
      assert List.first(evidence.mitigations).id == mitigation.id
    end

    test "assumptions can access their evidence" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      assumption = assumption_fixture(%{workspace_id: workspace.id})

      # Create association
      {:ok, _join} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceAssumption{
          evidence_id: evidence.id,
          assumption_id: assumption.id
        })

      # Load assumption with evidence
      assumption = Valentine.Repo.preload(Composer.get_assumption!(assumption.id), :evidence)
      assert length(assumption.evidence) == 1
      assert List.first(assumption.evidence).id == evidence.id
    end

    test "threats can access their evidence" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      threat = threat_fixture(%{workspace_id: workspace.id})

      # Create association
      {:ok, _join} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceThreat{
          evidence_id: evidence.id,
          threat_id: threat.id
        })

      # Load threat with evidence
      threat = Valentine.Repo.preload(Composer.get_threat!(threat.id), :evidence)
      assert length(threat.evidence) == 1
      assert List.first(threat.evidence).id == evidence.id
    end

    test "mitigations can access their evidence" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      # Create association
      {:ok, _join} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceMitigation{
          evidence_id: evidence.id,
          mitigation_id: mitigation.id
        })

      # Load mitigation with evidence
      mitigation = Valentine.Repo.preload(Composer.get_mitigation!(mitigation.id), :evidence)
      assert length(mitigation.evidence) == 1
      assert List.first(mitigation.evidence).id == evidence.id
    end

    test "evidence is deleted when workspace is deleted" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      evidence_id = evidence.id

      # Delete workspace
      Composer.delete_workspace(workspace)

      # Evidence should be deleted
      assert_raise Ecto.NoResultsError, fn -> Composer.get_evidence!(evidence_id) end
    end

    test "evidence associations are deleted when evidence is deleted" do
      workspace = workspace_fixture()
      evidence = evidence_fixture(%{workspace_id: workspace.id})
      assumption = assumption_fixture(%{workspace_id: workspace.id})
      threat = threat_fixture(%{workspace_id: workspace.id})
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      # Create associations
      {:ok, evidence_assumption} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceAssumption{
          evidence_id: evidence.id,
          assumption_id: assumption.id
        })

      {:ok, evidence_threat} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceThreat{
          evidence_id: evidence.id,
          threat_id: threat.id
        })

      {:ok, evidence_mitigation} =
        Valentine.Repo.insert(%Valentine.Composer.EvidenceMitigation{
          evidence_id: evidence.id,
          mitigation_id: mitigation.id
        })

      # Delete evidence
      Composer.delete_evidence(evidence)

      # Associations should be deleted
      assert Valentine.Repo.get(Valentine.Composer.EvidenceAssumption, evidence_assumption.id) ==
               nil

      assert Valentine.Repo.get(Valentine.Composer.EvidenceThreat, evidence_threat.id) == nil

      assert Valentine.Repo.get(Valentine.Composer.EvidenceMitigation, evidence_mitigation.id) ==
               nil

      # But the related entities should still exist
      assert Composer.get_assumption!(assumption.id)
      assert Composer.get_threat!(threat.id)
      assert Composer.get_mitigation!(mitigation.id)
    end
  end

  describe "NIST control linking" do
    test "create_evidence_with_linking/2 links evidence to assumption based on NIST control overlap" do
      workspace = workspace_fixture()

      # Create assumption with NIST control in tags
      assumption =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls are implemented",
          tags: ["AC-1", "security", "access-control"]
        })

      # Create evidence with matching NIST control
      evidence_attrs = %{
        workspace_id: workspace.id,
        description: "Test description",
        name: "NIST Control Evidence",
        evidence_type: :json_data,
        content: %{"audit_findings" => "AC-1 controls verified"},
        nist_controls: ["AC-1"]
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})
      assert evidence.name == "NIST Control Evidence"
      assert length(evidence.assumptions) == 1
      assert List.first(evidence.assumptions).id == assumption.id
    end

    test "create_evidence_with_linking/2 links evidence to threat based on NIST control overlap" do
      workspace = workspace_fixture()

      # Create threat with NIST control in tags
      threat =
        threat_fixture(%{
          workspace_id: workspace.id,
          threat_action: "Unauthorized access attempt",
          tags: ["AU-12", "logging", "monitoring"]
        })

      # Create evidence with matching NIST control
      evidence_attrs = %{
        workspace_id: workspace.id,
        description: "Test description",
        name: "Audit Evidence",
        evidence_type: :json_data,
        content: %{"findings" => "AU-12 logging verified"},
        nist_controls: ["AU-12"]
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})
      assert evidence.name == "Audit Evidence"
      assert length(evidence.threats) == 1
      assert List.first(evidence.threats).id == threat.id
    end

    test "create_evidence_with_linking/2 links evidence to mitigation based on NIST control overlap" do
      workspace = workspace_fixture()

      # Create mitigation with NIST control in tags
      mitigation =
        mitigation_fixture(%{
          workspace_id: workspace.id,
          content: "Implement proper network segmentation",
          tags: ["SC-7", "network", "segmentation"]
        })

      # Create evidence with matching NIST control
      evidence_attrs = %{
        workspace_id: workspace.id,
        description: "Test description",
        name: "Network Evidence",
        evidence_type: :json_data,
        content: %{"report" => "SC-7 network controls verified"},
        nist_controls: ["SC-7"]
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})
      assert evidence.name == "Network Evidence"
      assert length(evidence.mitigations) == 1
      assert List.first(evidence.mitigations).id == mitigation.id
    end

    test "create_evidence_with_linking/2 links evidence to multiple entities with overlapping NIST controls" do
      workspace = workspace_fixture()

      # Create entities with overlapping NIST controls in tags
      assumption =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls are implemented",
          tags: ["AC-1", "security"]
        })

      threat =
        threat_fixture(%{
          workspace_id: workspace.id,
          threat_action: "Unauthorized access",
          tags: ["AU-12", "logging"]
        })

      mitigation =
        mitigation_fixture(%{
          workspace_id: workspace.id,
          content: "Implement controls",
          tags: ["AC-1", "AU-12", "controls"]
        })

      # Create evidence with NIST controls that overlap with multiple entities
      evidence_attrs = %{
        workspace_id: workspace.id,
        name: "Multi-Control Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"findings" => "AC-1 and AU-12 controls verified"},
        nist_controls: ["AC-1", "AU-12"]
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})

      # Should link to assumption (has AC-1 tag)
      assert length(evidence.assumptions) == 1
      assert List.first(evidence.assumptions).id == assumption.id

      # Should link to threat (has AU-12 tag)
      assert length(evidence.threats) == 1
      assert List.first(evidence.threats).id == threat.id

      # Should link to mitigation (has both AC-1 and AU-12 tags)
      assert length(evidence.mitigations) == 1
      assert List.first(evidence.mitigations).id == mitigation.id
    end

    test "create_evidence_with_linking/2 respects workspace isolation for NIST control linking" do
      workspace1 = workspace_fixture(%{name: "Workspace 1"})
      workspace2 = workspace_fixture(%{name: "Workspace 2"})

      # Create assumption in different workspace with matching NIST control
      _other_assumption =
        assumption_fixture(%{
          workspace_id: workspace2.id,
          content: "Access controls in other workspace",
          tags: ["AC-1", "security"]
        })

      # Create evidence in workspace1 with NIST control
      evidence_attrs = %{
        workspace_id: workspace1.id,
        name: "Isolated Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"findings" => "AC-1 controls verified"},
        nist_controls: ["AC-1"]
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})

      # Should not link to entities from different workspace
      assert length(evidence.assumptions) == 0
      assert length(evidence.threats) == 0
      assert length(evidence.mitigations) == 0
    end

    test "create_evidence_with_linking/2 direct ID linking takes precedence over NIST control linking" do
      workspace = workspace_fixture()

      # Create assumption with tags that would match NIST controls
      _assumption_with_tags =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls assumption",
          tags: ["AC-1", "security"]
        })

      # Create different assumption for direct linking
      assumption_for_direct_link =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Different assumption",
          # No overlap with evidence NIST controls
          tags: ["SC-7", "network"]
        })

      evidence_attrs = %{
        workspace_id: workspace.id,
        description: "Test description",
        name: "Precedence Test Evidence",
        evidence_type: :json_data,
        content: %{"data" => "test"},
        # Would match assumption_with_tags
        nist_controls: ["AC-1"]
      }

      linking_opts = %{
        # Direct link to different entity
        assumption_id: assumption_for_direct_link.id
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, linking_opts)

      # Should only link to directly specified entity, not NIST control matches
      assert length(evidence.assumptions) == 1
      assert List.first(evidence.assumptions).id == assumption_for_direct_link.id
      # Should NOT link to assumption_with_tags despite NIST control overlap
    end

    test "create_evidence_with_linking/2 creates orphaned evidence when no NIST controls provided" do
      workspace = workspace_fixture()

      # Create entities with tags
      _assumption =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls assumption",
          tags: ["AC-1", "security"]
        })

      # Create evidence without NIST controls
      evidence_attrs = %{
        workspace_id: workspace.id,
        description: "Test description",
        name: "Evidence Without NIST Controls",
        evidence_type: :json_data,
        content: %{"data" => "test"}
        # No nist_controls field
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})

      # Should not link to any entities
      assert length(evidence.assumptions) == 0
      assert length(evidence.threats) == 0
      assert length(evidence.mitigations) == 0
    end

    test "create_evidence_with_linking/2 handles empty NIST controls array" do
      workspace = workspace_fixture()

      # Create entities with tags
      _assumption =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Access controls assumption",
          tags: ["AC-1", "security"]
        })

      # Create evidence with empty NIST controls
      evidence_attrs = %{
        workspace_id: workspace.id,
        description: "Test description",
        name: "Evidence With Empty NIST Controls",
        evidence_type: :json_data,
        content: %{"data" => "test"},
        # Empty array
        nist_controls: []
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})

      # Should not link to any entities
      assert length(evidence.assumptions) == 0
      assert length(evidence.threats) == 0
      assert length(evidence.mitigations) == 0
    end

    test "create_evidence_with_linking/2 links only to entities with overlapping tags" do
      workspace = workspace_fixture()

      # Create entities with different tags
      assumption_with_match =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Matching assumption",
          # Has AC-1
          tags: ["AC-1", "security"]
        })

      _assumption_without_match =
        assumption_fixture(%{
          workspace_id: workspace.id,
          content: "Non-matching assumption",
          # No AC-1
          tags: ["SC-7", "network"]
        })

      # Create evidence with specific NIST control
      evidence_attrs = %{
        workspace_id: workspace.id,
        description: "Test description",
        name: "Selective Linking Evidence",
        evidence_type: :json_data,
        content: %{"findings" => "AC-1 controls verified"},
        nist_controls: ["AC-1"]
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})

      # Should only link to entity with matching tag
      assert length(evidence.assumptions) == 1
      assert List.first(evidence.assumptions).id == assumption_with_match.id
      # Should not link to assumption_without_match
    end
  end

  describe "evidence linking" do
    test "create_evidence_with_linking/2 creates evidence and links to assumption" do
      workspace = workspace_fixture()
      assumption = assumption_fixture(%{workspace_id: workspace.id})

      evidence_attrs = %{
        workspace_id: workspace.id,
        name: "Linked Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test"}
      }

      linking_opts = %{assumption_id: assumption.id}

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, linking_opts)
      assert evidence.name == "Linked Evidence"
      assert length(evidence.assumptions) == 1
      assert List.first(evidence.assumptions).id == assumption.id
    end

    test "create_evidence_with_linking/2 creates evidence and links to multiple entities" do
      workspace = workspace_fixture()
      assumption = assumption_fixture(%{workspace_id: workspace.id})
      threat = threat_fixture(%{workspace_id: workspace.id})
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      evidence_attrs = %{
        workspace_id: workspace.id,
        name: "Multi-Linked Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test"}
      }

      linking_opts = %{
        assumption_id: assumption.id,
        threat_id: threat.id,
        mitigation_id: mitigation.id
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, linking_opts)
      assert length(evidence.assumptions) == 1
      assert length(evidence.threats) == 1
      assert length(evidence.mitigations) == 1
    end

    test "create_evidence_with_linking/2 handles invalid entity IDs gracefully" do
      workspace = workspace_fixture()
      invalid_uuid = "00000000-0000-0000-0000-000000000000"

      evidence_attrs = %{
        workspace_id: workspace.id,
        name: "Evidence with Invalid Links",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test"}
      }

      linking_opts = %{
        assumption_id: invalid_uuid,
        threat_id: invalid_uuid,
        mitigation_id: invalid_uuid
      }

      # Should create evidence successfully but with no links
      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, linking_opts)
      assert evidence.name == "Evidence with Invalid Links"
      assert length(evidence.assumptions) == 0
      assert length(evidence.threats) == 0
      assert length(evidence.mitigations) == 0
    end

    test "create_evidence_with_linking/2 prevents cross-workspace linking" do
      workspace1 = workspace_fixture(%{name: "Workspace 1"})
      workspace2 = workspace_fixture(%{name: "Workspace 2"})

      assumption = assumption_fixture(%{workspace_id: workspace2.id})

      evidence_attrs = %{
        workspace_id: workspace1.id,
        name: "Evidence in Workspace 1",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test"}
      }

      linking_opts = %{assumption_id: assumption.id}

      # Should create evidence but not link to assumption from different workspace
      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, linking_opts)
      assert evidence.workspace_id == workspace1.id
      assert length(evidence.assumptions) == 0
    end

    test "create_evidence_with_linking/2 creates orphaned evidence when no linking options" do
      workspace = workspace_fixture()

      evidence_attrs = %{
        workspace_id: workspace.id,
        name: "Orphaned Evidence",
        description: "Test description",
        evidence_type: :json_data,
        content: %{"data" => "test"}
      }

      assert {:ok, evidence} = Composer.create_evidence_with_linking(evidence_attrs, %{})
      assert evidence.name == "Orphaned Evidence"
      assert length(evidence.assumptions) == 0
      assert length(evidence.threats) == 0
      assert length(evidence.mitigations) == 0
    end

    test "create_evidence_with_linking/2 returns error for invalid evidence attributes" do
      workspace = workspace_fixture()

      invalid_attrs = %{
        workspace_id: workspace.id,
        # Missing required name and evidence_type
        content: %{"data" => "test"}
      }

      assert {:error, changeset} = Composer.create_evidence_with_linking(invalid_attrs, %{})
      assert changeset.errors[:name]
      assert changeset.errors[:evidence_type]
    end
  end
end
