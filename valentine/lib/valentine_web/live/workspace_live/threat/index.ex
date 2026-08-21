defmodule ValentineWeb.WorkspaceLive.Threat.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer.Threats

  alias Valentine.Composer.Workspaces
  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = Workspaces.get_workspace!(workspace_id, [:assumptions, :mitigations])
    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace.id)

    threats = Threats.list_threats_by_workspace(workspace.id, %{})

    {:ok,
     socket
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)
     |> assign(:filters, %{})
     |> assign(:threats, threats)
     |> assign(:mitre_tactic_values, mitre_tactic_values(threats))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :assumptions, %{"id" => id}) do
    threat =
      Threats.get_threat_for_workspace!(socket.assigns.workspace_id, id, [:assumptions])

    socket
    |> assign(:page_title, gettext("Link assumptions to threat"))
    |> assign(:assumptions, socket.assigns.workspace.assumptions)
    |> assign(:threat, threat)
  end

  defp apply_action(socket, :index, %{"workspace_id" => workspace_id} = _params) do
    socket
    |> assign(:page_title, gettext("Listing threats"))
    |> assign(:workspace_id, workspace_id)
  end

  defp apply_action(socket, :mitigations, %{"id" => id}) do
    threat =
      Threats.get_threat_for_workspace!(socket.assigns.workspace_id, id, [:mitigations])

    socket
    |> assign(:page_title, gettext("Link mitigations to threat"))
    |> assign(:mitigations, socket.assigns.workspace.mitigations)
    |> assign(:threat, threat)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Threats.get_threat_for_workspace(socket.assigns.workspace_id, id) do
      nil ->
        {:noreply, socket |> put_flash(:error, gettext("Threat not found"))}

      threat ->
        case Threats.delete_threat(threat) do
          {:ok, _} ->
            threats =
              Threats.list_threats_by_workspace(
                socket.assigns.workspace_id,
                socket.assigns.filters
              )

            log(
              :info,
              socket.assigns.current_user,
              "delete",
              %{workspace: socket.assigns.workspace_id, threat: id},
              "threat"
            )

            # Remove this threat from the associated data flow diagrams
            Valentine.Composer.DataFlowDiagram.remove_linked_threats(
              socket.assigns.workspace_id,
              id
            )

            {:noreply,
             socket
             |> put_flash(:info, gettext("Threat deleted successfully"))
             |> assign(:mitre_tactic_values, mitre_tactic_values(threats))
             |> assign(:threats, threats)}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, gettext("Failed to delete threat"))}
        end
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    threats = Threats.list_threats_by_workspace(socket.assigns.workspace_id, %{})

    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign(:threats, threats)
     |> assign(:mitre_tactic_values, mitre_tactic_values(threats))}
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    threats = Threats.list_threats_by_workspace(socket.assigns.workspace_id, filters)

    {
      :noreply,
      socket
      |> assign(:filters, filters)
      |> assign(:threats, threats)
      |> assign(:mitre_tactic_values, mitre_tactic_values(threats))
    }
  end

  @impl true
  def handle_info(
        {_, {:saved, _threat}},
        socket
      ) do
    threats =
      Threats.list_threats_by_workspace(socket.assigns.workspace_id, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:threats, threats)
     |> assign(:mitre_tactic_values, mitre_tactic_values(threats))}
  end

  @impl true
  def handle_info(%{topic: "workspace_" <> workspace_id}, socket) do
    threats = Threats.list_threats_by_workspace(workspace_id, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:threats, threats)
     |> assign(:mitre_tactic_values, mitre_tactic_values(threats))}
  end

  defp mitre_tactic_values(threats) do
    threats
    |> Enum.map(& &1.mitre_tactic)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
