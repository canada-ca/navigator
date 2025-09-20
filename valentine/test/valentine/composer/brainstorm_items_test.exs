defmodule Valentine.Composer.BrainstormItemsTest do
  use Valentine.DataCase

  alias Valentine.Composer

  import Valentine.ComposerFixtures

  describe "list_brainstorm_items/2" do
    test "returns all brainstorm items for a workspace" do
      workspace = workspace_fixture()

      {:ok, item1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "First threat"
        })

      {:ok, item2} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :assumption,
          raw_text: "First assumption"
        })

      items = Composer.list_brainstorm_items(workspace.id)

      assert length(items) == 2
      assert Enum.any?(items, &(&1.id == item1.id))
      assert Enum.any?(items, &(&1.id == item2.id))
    end

    test "filters by type" do
      workspace = workspace_fixture()

      {:ok, threat_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "A threat"
        })

      {:ok, _assumption_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :assumption,
          raw_text: "An assumption"
        })

      items = Composer.list_brainstorm_items(workspace.id, %{type: :threat})

      assert length(items) == 1
      assert hd(items).id == threat_item.id
    end

    test "filters by status" do
      workspace = workspace_fixture()

      {:ok, draft_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Draft item"
        })

      {:ok, _clustered_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Clustered item",
          status: :clustered
        })

      items = Composer.list_brainstorm_items(workspace.id, %{status: :draft})

      assert length(items) == 1
      assert hd(items).id == draft_item.id
    end

    test "orders by position and inserted_at" do
      workspace = workspace_fixture()

      {:ok, item1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Item with position 200",
          position: 200
        })

      {:ok, item2} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Item with position 100",
          position: 100
        })

      items = Composer.list_brainstorm_items(workspace.id)

      assert length(items) == 2
      # position 100 first
      assert Enum.at(items, 0).id == item2.id
      # position 200 second
      assert Enum.at(items, 1).id == item1.id
    end
  end

  describe "list_brainstorm_items_by_type/2" do
    test "groups items by type" do
      workspace = workspace_fixture()

      {:ok, threat1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "First threat"
        })

      {:ok, threat2} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Second threat"
        })

      {:ok, assumption1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :assumption,
          raw_text: "First assumption"
        })

      grouped = Composer.list_brainstorm_items_by_type(workspace.id)

      assert length(grouped[:threat]) == 2
      assert length(grouped[:assumption]) == 1
      assert Enum.any?(grouped[:threat], &(&1.id == threat1.id))
      assert Enum.any?(grouped[:threat], &(&1.id == threat2.id))
      assert Enum.any?(grouped[:assumption], &(&1.id == assumption1.id))
    end
  end

  describe "list_cluster_items/2" do
    test "returns items in a specific cluster" do
      workspace = workspace_fixture()

      {:ok, cluster_item1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Clustered item 1",
          cluster_key: "cluster_123"
        })

      {:ok, cluster_item2} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Clustered item 2",
          cluster_key: "cluster_123"
        })

      {:ok, _other_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Different cluster",
          cluster_key: "cluster_456"
        })

      items = Composer.list_cluster_items(workspace.id, "cluster_123")

      assert length(items) == 2
      assert Enum.any?(items, &(&1.id == cluster_item1.id))
      assert Enum.any?(items, &(&1.id == cluster_item2.id))
    end
  end

  describe "list_assembly_candidates/2" do
    test "returns items with clustered or candidate status" do
      workspace = workspace_fixture()

      {:ok, clustered_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Clustered item",
          status: :clustered
        })

      {:ok, candidate_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Candidate item",
          status: :candidate
        })

      {:ok, _draft_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Draft item",
          status: :draft
        })

      items = Composer.list_assembly_candidates(workspace.id)

      assert length(items) == 2
      assert Enum.any?(items, &(&1.id == clustered_item.id))
      assert Enum.any?(items, &(&1.id == candidate_item.id))
    end

    test "filters by cluster_key when provided" do
      workspace = workspace_fixture()

      {:ok, target_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Target item",
          status: :clustered,
          cluster_key: "target_cluster"
        })

      {:ok, _other_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Other item",
          status: :clustered,
          cluster_key: "other_cluster"
        })

      items = Composer.list_assembly_candidates(workspace.id, "target_cluster")

      assert length(items) == 1
      assert hd(items).id == target_item.id
    end
  end

  describe "list_backlog_items/2" do
    test "returns items not used or archived" do
      workspace = workspace_fixture()

      {:ok, draft_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Draft item",
          status: :draft
        })

      {:ok, clustered_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Clustered item",
          status: :clustered
        })

      {:ok, _used_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Used item",
          status: :used
        })

      {:ok, _archived_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Archived item",
          status: :archived
        })

      items = Composer.list_backlog_items(workspace.id)

      assert length(items) == 2
      assert Enum.any?(items, &(&1.id == draft_item.id))
      assert Enum.any?(items, &(&1.id == clustered_item.id))
    end
  end

  describe "create_brainstorm_item/1" do
    test "creates a brainstorm item with valid data" do
      workspace = workspace_fixture()

      assert {:ok, item} =
               Composer.create_brainstorm_item(%{
                 workspace_id: workspace.id,
                 type: :threat,
                 raw_text: "A new threat item"
               })

      assert item.workspace_id == workspace.id
      assert item.type == :threat
      assert item.raw_text == "A new threat item"
      assert item.status == :draft
      assert item.normalized_text == "a new threat item"
    end

    test "returns error changeset with invalid data" do
      assert {:error, changeset} = Composer.create_brainstorm_item(%{})

      assert %{workspace_id: ["can't be blank"]} = errors_on(changeset)
      assert %{type: ["can't be blank"]} = errors_on(changeset)
      assert %{raw_text: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_brainstorm_item/2" do
    test "updates a brainstorm item with valid data" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Original text"
        })

      assert {:ok, updated_item} =
               Composer.update_brainstorm_item(item, %{
                 raw_text: "Updated text",
                 status: :clustered
               })

      assert updated_item.raw_text == "Updated text"
      assert updated_item.status == :clustered
      assert updated_item.normalized_text == "updated text"
    end

    test "returns error changeset with invalid data" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Original text"
        })

      assert {:error, changeset} =
               Composer.update_brainstorm_item(item, %{
                 # Invalid transition from draft to used
                 status: :used
               })

      assert %{status: ["invalid transition from draft to used"]} = errors_on(changeset)
    end
  end

  describe "assign_to_cluster/2" do
    test "assigns item to cluster" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Item to cluster"
        })

      assert {:ok, updated_item} = Composer.assign_to_cluster(item, "cluster_123")
      assert updated_item.cluster_key == "cluster_123"
    end
  end

  describe "mark_used_in_threat/2 and unmark_used_in_threat/2" do
    test "marks and unmarks item as used in threat" do
      workspace = workspace_fixture()

      {:ok, item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Item for threat",
          status: :candidate
        })

      # Mark as used
      assert {:ok, updated_item} = Composer.mark_used_in_threat(item, 123)
      assert updated_item.used_in_threat_ids == [123]
      assert updated_item.status == :used

      # Unmark from threat
      assert {:ok, final_item} = Composer.unmark_used_in_threat(updated_item, 123)
      assert final_item.used_in_threat_ids == []
      assert final_item.status == :candidate
    end
  end

  describe "get_funnel_metrics/1" do
    test "returns counts by status" do
      workspace = workspace_fixture()

      # Create items with different statuses
      Enum.each(1..3, fn _ ->
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Draft item",
          status: :draft
        })
      end)

      Enum.each(1..2, fn _ ->
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Clustered item",
          status: :clustered
        })
      end)

      metrics = Composer.get_funnel_metrics(workspace.id)

      assert metrics[:draft] == 3
      assert metrics[:clustered] == 2
    end
  end

  describe "get_type_metrics/1" do
    test "returns counts by type" do
      workspace = workspace_fixture()

      # Create items with different types
      Enum.each(1..3, fn _ ->
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "Threat item"
        })
      end)

      Enum.each(1..2, fn _ ->
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :assumption,
          raw_text: "Assumption item"
        })
      end)

      metrics = Composer.get_type_metrics(workspace.id)

      assert metrics[:threat] == 3
      assert metrics[:assumption] == 2
    end
  end
end
