defmodule ValentineWeb.WorkspaceLive.Threat.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = Composer.get_workspace!(workspace_id, [:assumptions, :mitigations])
    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace.id)

    threats = Composer.list_threats_by_workspace(workspace.id, %{})

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
    socket
    |> assign(:page_title, gettext("Link assumptions to threat"))
    |> assign(:assumptions, socket.assigns.workspace.assumptions)
    |> assign(:threat, Composer.get_threat!(id, [:assumptions]))
  end

  defp apply_action(socket, :index, %{"workspace_id" => workspace_id} = _params) do
    socket
    |> assign(:page_title, gettext("Listing threats"))
    |> assign(:workspace_id, workspace_id)
  end

  defp apply_action(socket, :mitigations, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Link mitigations to threat"))
    |> assign(:mitigations, socket.assigns.workspace.mitigations)
    |> assign(:threat, Composer.get_threat!(id, [:mitigations]))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Composer.get_threat!(id) do
      nil ->
        {:noreply, socket |> put_flash(:error, gettext("Threat not found"))}

      threat ->
        case Composer.delete_threat(threat) do
          {:ok, _} ->
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
             |> assign(:mitre_tactic_values, mitre_tactic_values(socket.assigns.workspace_id))
             |> assign(
               :threats,
               Composer.list_threats_by_workspace(
                 socket.assigns.workspace_id,
                 socket.assigns.filters
               )
             )}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, gettext("Failed to delete threat"))}
        end
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    threats = Composer.list_threats_by_workspace(socket.assigns.workspace_id, %{})

    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign(:threats, threats)
     |> assign(:mitre_tactic_values, mitre_tactic_values(threats))}
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    threats = Composer.list_threats_by_workspace(socket.assigns.workspace_id, filters)

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
      Composer.list_threats_by_workspace(socket.assigns.workspace_id, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:threats, threats)
     |> assign(:mitre_tactic_values, mitre_tactic_values(threats))}
  end

  @impl true
  def handle_info(%{topic: "workspace_" <> workspace_id}, socket) do
    threats = Composer.list_threats_by_workspace(workspace_id, socket.assigns.filters)

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
