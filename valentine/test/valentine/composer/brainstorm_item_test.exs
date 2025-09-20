defmodule Valentine.Composer.BrainstormItemTest do
  use Valentine.DataCase

  alias Valentine.Composer.BrainstormItem
  alias Valentine.Composer

  import Valentine.ComposerFixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "A malicious user could exploit SQL injection vulnerabilities"
        })

      assert changeset.valid?
      assert changeset.changes.workspace_id == workspace.id
      assert changeset.changes.type == :threat

      assert changeset.changes.raw_text ==
               "A malicious user could exploit SQL injection vulnerabilities"

      assert Map.get(changeset.changes, :status, :draft) == :draft
    end

    test "invalid changeset without required fields" do
      changeset = BrainstormItem.changeset(%BrainstormItem{}, %{})

      refute changeset.valid?
      assert %{workspace_id: ["can't be blank"]} = errors_on(changeset)
      assert %{type: ["can't be blank"]} = errors_on(changeset)
      assert %{raw_text: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset with invalid type" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :invalid_type,
          raw_text: "Some text"
        })

      refute changeset.valid?
      assert %{type: ["is invalid"]} = errors_on(changeset)
    end

    test "invalid changeset with invalid status" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some text",
          status: :invalid_status
        })

      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "validates raw_text length" do
      workspace = workspace_fixture()

      # Too short
      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: ""
        })

      refute changeset.valid?
      assert %{raw_text: ["can't be blank"]} = errors_on(changeset)

      # Too long
      long_text = String.duplicate("a", 10_001)

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: long_text
        })

      refute changeset.valid?
      assert %{raw_text: ["should be at most 10000 character(s)"]} = errors_on(changeset)
    end

    test "validates position is non-negative" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some text",
          position: -1
        })

      refute changeset.valid?
      assert %{position: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end
  end

  describe "normalize_text/1" do
    test "normalizes text according to rules" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "  A Malicious   User Could Exploit   SQL Injection!!! "
        })

      assert changeset.changes.normalized_text == "a Malicious User Could Exploit SQL Injection"
    end

    test "handles empty text" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "   "
        })

      assert changeset.changes.normalized_text == ""
    end

    test "handles single character" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "A."
        })

      assert changeset.changes.normalized_text == "a"
    end

    test "strips multiple terminal punctuation" do
      workspace = workspace_fixture()

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Text with punctuation?!?."
        })

      assert changeset.changes.normalized_text == "text with punctuation"
    end
  end

  describe "status transitions" do
    test "allows valid transitions" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          status: :draft
        })

      # draft -> clustered
      changeset = BrainstormItem.changeset(item, %{status: :clustered})
      assert changeset.valid?

      # clustered -> candidate
      {:ok, item} = Composer.update_brainstorm_item(item, %{status: :clustered})
      changeset = BrainstormItem.changeset(item, %{status: :candidate})
      assert changeset.valid?

      # candidate -> used
      {:ok, item} = Composer.update_brainstorm_item(item, %{status: :candidate})
      changeset = BrainstormItem.changeset(item, %{status: :used})
      assert changeset.valid?

      # used -> archived
      {:ok, item} = Composer.update_brainstorm_item(item, %{status: :used})
      changeset = BrainstormItem.changeset(item, %{status: :archived})
      assert changeset.valid?
    end

    test "prevents invalid transitions" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          status: :draft
        })

      # draft -> used (invalid)
      changeset = BrainstormItem.changeset(item, %{status: :used})
      refute changeset.valid?
      assert %{status: ["invalid transition from draft to used"]} = errors_on(changeset)

      # Test other invalid transitions
      {:ok, item} = Composer.update_brainstorm_item(item, %{status: :clustered})

      # clustered -> draft (invalid)
      changeset = BrainstormItem.changeset(item, %{status: :draft})
      refute changeset.valid?
      assert %{status: ["invalid transition from clustered to draft"]} = errors_on(changeset)
    end

    test "allows staying in same status" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          status: :draft
        })

      changeset = BrainstormItem.changeset(item, %{status: :draft})
      assert changeset.valid?
    end
  end

  describe "duplicate detection" do
    test "sets duplicate warning when normalized text matches" do
      workspace = workspace_fixture()

      # Create first item and ensure it's saved
      {:ok, item1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "SQL injection vulnerability"
        })

      # Create second item with same normalized text but different raw text
      # Note: normalization only lowercases first char, so case of other chars must match
      {:ok, item2} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          # Same casing, different spacing/punctuation
          raw_text: "  SQL injection vulnerability!!! "
        })

      # Check that both have the same normalized text
      assert item1.normalized_text == item2.normalized_text

      # The second item should have duplicate warning in metadata
      assert item2.metadata[:duplicate_warning] == true
    end

    test "does not set duplicate warning for different types" do
      workspace = workspace_fixture()

      # Create first item as threat
      {:ok, _item1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "SQL injection vulnerability"
        })

      # Create second item as assumption with same text
      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :assumption,
          raw_text: "SQL injection vulnerability"
        })

      refute Map.has_key?(changeset.changes[:metadata] || %{}, :duplicate_warning)
    end

    test "does not set duplicate warning for different workspaces" do
      workspace1 = workspace_fixture()
      workspace2 = workspace_fixture()

      # Create first item in workspace1
      {:ok, _item1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace1.id,
          type: :threat,
          raw_text: "SQL injection vulnerability"
        })

      # Create second item in workspace2 with same text
      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace2.id,
          type: :threat,
          raw_text: "SQL injection vulnerability"
        })

      refute Map.has_key?(changeset.changes[:metadata] || %{}, :duplicate_warning)
    end
  end

  describe "mark_used_in_threat/2" do
    test "adds threat ID to used_in_threat_ids and updates status" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          status: :candidate
        })

      changeset = BrainstormItem.mark_used_in_threat(item, 123)
      assert changeset.changes.used_in_threat_ids == [123]
      assert changeset.changes.status == :used
    end

    test "does not duplicate threat IDs" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          used_in_threat_ids: [123]
        })

      result = BrainstormItem.mark_used_in_threat(item, 123)
      assert {:ok, ^item} = result
    end

    test "maintains sorted order of threat IDs" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          used_in_threat_ids: [100, 300]
        })

      changeset = BrainstormItem.mark_used_in_threat(item, 200)
      assert changeset.changes.used_in_threat_ids == [100, 200, 300]
    end
  end

  describe "unmark_used_in_threat/2" do
    test "removes threat ID and updates status when no more threats" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          used_in_threat_ids: [123],
          status: :used
        })

      changeset = BrainstormItem.unmark_used_in_threat(item, 123)
      assert changeset.changes.used_in_threat_ids == []
      assert changeset.changes.status == :candidate
    end

    test "keeps status as used when other threats remain" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Some threat",
          used_in_threat_ids: [123, 456],
          status: :used
        })

      changeset = BrainstormItem.unmark_used_in_threat(item, 123)
      assert changeset.changes.used_in_threat_ids == [456]
      # Status should remain :used (might not be in changes if unchanged)
      assert Map.get(changeset.changes, :status, item.status) == :used
    end
  end
end
