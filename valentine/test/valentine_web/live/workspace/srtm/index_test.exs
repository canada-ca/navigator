defmodule ValentineWeb.WorkspaceLive.SRTM.IndexTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  setup do
    control = control_fixture(%{nist_id: "AC-1", tags: ["A", "B", "C"]})
    workspace = workspace_fixture(%{cloud_profile: "A", cloud_profile_type: "B"})

    workspace =
      Valentine.Composer.get_workspace!(workspace.id,
        mitigations: [:assumptions, :threats],
        threats: [:assumptions, :mitigations],
        assumptions: [:threats, :mitigations],
        evidence: []
      )

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        live_action: nil,
        filters: nil,
        flash: %{},
        workspace: workspace
      }
    }

    %{
      control: control,
      socket: socket,
      workspace: workspace
    }
  end

  describe "mount/3" do
    test "mounts the component and assigns the correct assigns", %{
      control: control,
      workspace: workspace,
      socket: socket
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.mount(
          %{"workspace_id" => workspace.id},
          nil,
          socket
        )

      assert socket.assigns.controls == %{
               not_allocated: %{"AC-1" => [control]},
               out_of_scope: %{},
               in_scope: %{}
             }

      assert socket.assigns.workspace.id == workspace.id
    end

    test "mounts tagged assumptions into the correct category", %{
      workspace: workspace,
      socket: socket
    } do
      assumption =
        assumption_fixture(%{
          tags: ["AC-1"],
          workspace_id: workspace.id
        })

      {:ok, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.mount(
          %{"workspace_id" => workspace.id},
          nil,
          socket
        )

      [{_, [assigned_assumption]}] = socket.assigns.controls[:out_of_scope]["AC-1"]
      assert assigned_assumption.id == assumption.id
      assert socket.assigns.workspace.id == workspace.id
    end

    test "mounts mitigations into the correct category", %{
      workspace: workspace,
      socket: socket
    } do
      mitigation =
        mitigation_fixture(%{
          tags: ["AC-1"],
          workspace_id: workspace.id
        })

      {:ok, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.mount(
          %{"workspace_id" => workspace.id},
          nil,
          socket
        )

      [{_, [assigned_mitigation]}] = socket.assigns.controls[:in_scope]["AC-1"]
      assert assigned_mitigation.id == mitigation.id
      assert socket.assigns.workspace.id == workspace.id
    end

    test "mounts threats into the correct category", %{
      workspace: workspace,
      socket: socket
    } do
      threat =
        threat_fixture(%{
          tags: ["AC-1"],
          workspace_id: workspace.id
        })

      {:ok, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.mount(
          %{"workspace_id" => workspace.id},
          nil,
          socket
        )

      [{_, [assigned_threat]}] = socket.assigns.controls[:in_scope]["AC-1"]
      assert assigned_threat.id == threat.id
      assert socket.assigns.workspace.id == workspace.id
    end
  end

  describe "handle_event/3" do
    test "clears the filters", %{
      control: control,
      socket: socket
    } do
      socket = put_in(socket.assigns.filters, %{"profile" => "Profile 1"})

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_event(
          "clear_filters",
          %{},
          socket
        )

      assert socket.assigns.filters == %{}

      assert socket.assigns.controls == %{
               not_allocated: %{"AC-1" => [control]},
               out_of_scope: %{},
               in_scope: %{}
             }
    end

    test "evidence filter is initialized to :all on mount", %{
      workspace: workspace,
      socket: socket
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.mount(
          %{"workspace_id" => workspace.id},
          nil,
          socket
        )

      # Behavior: Default state should show all controls
      assert socket.assigns.evidence_filter == :all
    end

    test "selecting a valid evidence filter updates the state", %{socket: socket} do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_event(
          "select_evidence_filter",
          %{"item" => "needs_evidence"},
          socket
        )

      # Behavior: User can filter to see only controls needing evidence
      assert socket.assigns.evidence_filter == :needs_evidence
    end

    test "selecting another valid filter updates correctly", %{socket: socket} do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_event(
          "select_evidence_filter",
          %{"item" => "has_evidence"},
          socket
        )

      # Behavior: User can filter to see only controls with evidence attached
      assert socket.assigns.evidence_filter == :has_evidence
    end

    test "invalid filter input is handled safely", %{socket: socket} do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_event(
          "select_evidence_filter",
          %{"item" => "malicious_value"},
          socket
        )

      # Behavior: System should not crash and falls back to safe default
      assert socket.assigns.evidence_filter == :all
    end

    test "clearing filters resets evidence filter to all", %{socket: socket} do
      socket =
        socket
        |> put_in([Access.key(:assigns), :evidence_filter], :needs_evidence)

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_event(
          "clear_filters",
          %{},
          socket
        )

      # Behavior: Clearing filters should reset evidence view to show all controls
      assert socket.assigns.evidence_filter == :all
    end
  end

  describe "handle_info/2" do
    test "updating filters resets evidence filter to all", %{
      control: control,
      socket: socket
    } do
      socket =
        socket
        |> put_in([Access.key(:assigns), :filters], %{"profile" => "Profile 1"})
        |> put_in([Access.key(:assigns), :evidence_filter], :has_evidence)

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_info(
          {:update_filter, %{"profile" => control.tags}},
          socket
        )

      # Behavior: When main filters change, evidence filter should reset
      assert socket.assigns.evidence_filter == :all

      assert socket.assigns.filters == %{"profile" => control.tags}

      assert socket.assigns.controls == %{
               not_allocated: %{"AC-1" => [control]},
               out_of_scope: %{},
               in_scope: %{}
             }
    end

    test "updates the filters (legacy test)", %{
      control: control,
      socket: socket
    } do
      socket = put_in(socket.assigns.filters, %{"profile" => "Profile 1"})

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_info(
          {:update_filter, %{"profile" => control.tags}},
          socket
        )

      assert socket.assigns.filters == %{"profile" => control.tags}

      assert socket.assigns.controls == %{
               not_allocated: %{"AC-1" => [control]},
               out_of_scope: %{},
               in_scope: %{}
             }
    end
  end

  describe "handle_params/3" do
    test "applies the action", %{
      socket: socket
    } do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.SRTM.Index.handle_params(
          %{},
          nil,
          socket
        )

      assert socket.assigns.page_title == "Security Requirements Traceability Matrix"
    end
  end
end
