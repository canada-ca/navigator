defmodule ValentineWeb.WorkspaceLive.Components.EvidenceComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Components.EvidenceComponent

  defp create_evidence(_) do
    workspace = workspace_fixture()
    evidence = evidence_fixture(%{workspace_id: workspace.id})

    assigns = %{__changed__: %{}, evidence: evidence, id: "evidence-component"}

    %{assigns: assigns, evidence: evidence, workspace: workspace}
  end

  describe "render" do
    setup [:create_evidence]

    test "displays evidence with all fields populated", %{assigns: assigns} do
      html = render_component(EvidenceComponent, assigns)
      assert html =~ assigns.evidence.name
      assert html =~ assigns.evidence.description
      assert html =~ "JSON Content"
      assert html =~ "##{assigns.evidence.numeric_id}"
    end

    test "displays evidence without optional fields", %{assigns: assigns} do
      evidence = Map.merge(assigns.evidence, %{description: nil, tags: [], nist_controls: []})
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ evidence.name
      # Check that description is not rendered (if it exists, it would appear in the HTML)
      # More specific check than looking for any <p tag
      refute html =~ ~r/<div[^>]*class="[^"]*description/
    end

    test "displays updated timestamp when modified", %{assigns: assigns} do
      updated_at = DateTime.add(assigns.evidence.inserted_at, 3600, :second)
      evidence = Map.put(assigns.evidence, :updated_at, updated_at)
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ "Created"
      assert html =~ "Updated"
    end

    test "hides updated timestamp when not modified", %{assigns: assigns} do
      evidence = Map.put(assigns.evidence, :updated_at, assigns.evidence.inserted_at)
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ "Created"
      refute html =~ "Updated"
    end

    test "displays all action buttons with correct IDs", %{assigns: assigns} do
      html = render_component(EvidenceComponent, assigns)
      evidence_id = assigns.evidence.id
      assert html =~ "linked-evidence-assumptions-#{evidence_id}"
      assert html =~ "linked-evidence-threats-#{evidence_id}"
      assert html =~ "linked-evidence-mitigations-#{evidence_id}"
      assert html =~ "edit-evidence-#{evidence_id}"
      assert html =~ "delete-evidence-#{evidence_id}"
    end

    test "displays entity counters for linked entities", %{assigns: assigns, workspace: workspace} do
      assumption = assumption_fixture(%{workspace_id: workspace.id})
      threat = threat_fixture(%{workspace_id: workspace.id})
      mitigation = mitigation_fixture(%{workspace_id: workspace.id})

      evidence =
        Map.merge(assigns.evidence, %{
          assumptions: [assumption],
          threats: [threat],
          mitigations: [mitigation]
        })

      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ ">1<"
    end

    test "handles zero entity counts", %{assigns: assigns} do
      evidence = Map.merge(assigns.evidence, %{assumptions: [], threats: [], mitigations: []})
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ ">0<"
    end

    test "format_evidence_type for json_data type", %{assigns: assigns} do
      evidence = Map.put(assigns.evidence, :evidence_type, :json_data)
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ "JSON Content"
    end

    test "format_evidence_type for blob_store_link type", %{assigns: assigns} do
      evidence = Map.put(assigns.evidence, :evidence_type, :blob_store_link)
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ "File Link"
    end

    test "format_evidence_type for other types", %{assigns: assigns} do
      evidence = Map.put(assigns.evidence, :evidence_type, :other)
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ "Other"
    end

    test "format_date helper function", %{assigns: assigns} do
      html = render_component(EvidenceComponent, assigns)
      # Check for date format YYYY-MM-DD HH:MM
      assert html =~ ~r/\d{4}-\d{2}-\d{2} \d{2}:\d{2}/
    end

    test "assoc_length with loaded associations", %{assigns: assigns, workspace: workspace} do
      assumption = assumption_fixture(%{workspace_id: workspace.id})
      evidence = Map.put(assigns.evidence, :assumptions, [assumption])
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ ">1<"
    end

    test "assoc_length with unloaded associations", %{assigns: assigns} do
      evidence = Map.put(assigns.evidence, :assumptions, %Ecto.Association.NotLoaded{})
      assigns = Map.put(assigns, :evidence, evidence)
      html = render_component(EvidenceComponent, assigns)
      assert html =~ ">0<"
    end
  end
end
