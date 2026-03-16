defmodule ValentineWeb.WorkspaceLive.ThreatAgent.IndexTest do
  use ValentineWeb.ConnCase

  import Mock
  import Valentine.ComposerFixtures

  alias Valentine.Composer

  setup do
    workspace = workspace_fixture()
    threat_agent = threat_agent_fixture(%{workspace_id: workspace.id, name: "GC End User"})

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        live_action: nil,
        current_user: workspace.owner,
        flash: %{},
        workspace_id: workspace.id,
        workspace: workspace
      }
    }

    %{socket: socket, workspace: workspace, threat_agent: threat_agent}
  end

  describe "mount/3" do
    test "assigns workspace_id and threat agents", %{socket: socket, workspace: workspace} do
      {:ok, mounted_socket} =
        ValentineWeb.WorkspaceLive.ThreatAgent.Index.mount(
          %{"workspace_id" => workspace.id},
          %{},
          socket
        )

      assert mounted_socket.assigns.workspace_id == workspace.id
      assert length(mounted_socket.assigns.threat_agents) == 1
    end
  end

  describe "handle_params/3" do
    test "sets page title for index action", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.live_action, :index)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ThreatAgent.Index.handle_params(
          %{"workspace_id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Listing Threat Agents"
    end
  end

  describe "handle_info td level updates" do
    test "updates td level from the pill selector", %{socket: socket, threat_agent: threat_agent} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ThreatAgent.Index.handle_info(
          {:selected_label_dropdown, "threat-agent-td-level-#{threat_agent.id}", "td_level",
           "td6"},
          socket
        )

      assert Enum.any?(
               updated_socket.assigns.threat_agents,
               &(&1.id == threat_agent.id and &1.td_level == :td6)
             )
    end
  end

  describe "handle_event delete" do
    test "successfully deletes threat agent", %{socket: socket, threat_agent: threat_agent} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.ThreatAgent.Index.handle_event(
          "delete",
          %{"id" => threat_agent.id},
          socket
        )

      assert updated_socket.assigns.flash["info"] =~ "deleted successfully"
    end

    test "handles not found threat agent", %{socket: socket} do
      with_mock Composer, get_threat_agent!: fn _id -> nil end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.ThreatAgent.Index.handle_event(
            "delete",
            %{"id" => nil},
            socket
          )

        assert updated_socket.assigns.flash["error"] =~ "not found"
      end
    end
  end
end
