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
        evidence_type: :json_data,
        # Missing content for json_data type
        blob_store_url: "https://example.com/doc.pdf"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(invalid_attrs)
      assert "must be provided when evidence_type is json_data" in errors_on(changeset).content
    end

    test "create_evidence/1 with invalid blob_store_link type returns error changeset" do
      workspace = workspace_fixture()
      invalid_attrs = %{
        workspace_id: workspace.id,
        name: "Test Evidence",
        evidence_type: :blob_store_link,
        # Missing blob_store_url for blob_store_link type
        content: %{"data" => "some data"}
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Composer.create_evidence(invalid_attrs)
      assert "must be provided when evidence_type is blob_store_link" in errors_on(changeset).blob_store_url
    end

    test "create_evidence/1 with invalid NIST controls returns error changeset" do
      workspace = workspace_fixture()
      invalid_attrs = %{
        workspace_id: workspace.id,
        name: "Test Evidence",
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
      
      {:ok, evidence1} = Composer.create_evidence(%{
        workspace_id: workspace.id,
        name: "Evidence 1",
        evidence_type: :json_data,
        content: %{"data" => "test1"}
      })
      
      {:ok, evidence2} = Composer.create_evidence(%{
        workspace_id: workspace.id,
        name: "Evidence 2",
        evidence_type: :json_data,
        content: %{"data" => "test2"}
      })

      # Different workspace should start from 1 again
      other_workspace = workspace_fixture()
      {:ok, evidence3} = Composer.create_evidence(%{
        workspace_id: other_workspace.id,
        name: "Evidence 3",
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
      {:ok, _join} = Valentine.Repo.insert(%Valentine.Composer.EvidenceAssumption{
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
      {:ok, _join} = Valentine.Repo.insert(%Valentine.Composer.EvidenceThreat{
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
      {:ok, _join} = Valentine.Repo.insert(%Valentine.Composer.EvidenceMitigation{
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
      {:ok, _join} = Valentine.Repo.insert(%Valentine.Composer.EvidenceAssumption{
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
      {:ok, _join} = Valentine.Repo.insert(%Valentine.Composer.EvidenceThreat{
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
      {:ok, _join} = Valentine.Repo.insert(%Valentine.Composer.EvidenceMitigation{
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
      {:ok, evidence_assumption} = Valentine.Repo.insert(%Valentine.Composer.EvidenceAssumption{
        evidence_id: evidence.id,
        assumption_id: assumption.id
      })
      {:ok, evidence_threat} = Valentine.Repo.insert(%Valentine.Composer.EvidenceThreat{
        evidence_id: evidence.id,
        threat_id: threat.id
      })
      {:ok, evidence_mitigation} = Valentine.Repo.insert(%Valentine.Composer.EvidenceMitigation{
        evidence_id: evidence.id,
        mitigation_id: mitigation.id
      })

      # Delete evidence
      Composer.delete_evidence(evidence)

      # Associations should be deleted
      assert Valentine.Repo.get(Valentine.Composer.EvidenceAssumption, evidence_assumption.id) == nil
      assert Valentine.Repo.get(Valentine.Composer.EvidenceThreat, evidence_threat.id) == nil
      assert Valentine.Repo.get(Valentine.Composer.EvidenceMitigation, evidence_mitigation.id) == nil

      # But the related entities should still exist
      assert Composer.get_assumption!(assumption.id)
      assert Composer.get_threat!(threat.id)
      assert Composer.get_mitigation!(mitigation.id)
    end
  end
end