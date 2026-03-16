defmodule ValentineWeb.WorkspaceLive.ThreatAgent.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.ThreatAgent

  @impl true
  def mount(%{"workspace_id" => workspace_id}, _session, socket) do
    workspace = get_workspace(workspace_id)

    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace.id)

    {:ok,
     socket
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)
     |> assign(:threat_agents, Composer.list_threat_agents(workspace_id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Threat Agent"))
    |> assign(:threat_agent, Composer.get_threat_agent!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Threat Agent"))
    |> assign(:threat_agent, %ThreatAgent{workspace_id: socket.assigns.workspace_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Threat Agents"))
  end

  @impl true
  def handle_info({_, {:saved, _threat_agent}}, socket) do
    {:noreply,
     socket
     |> assign(:threat_agents, Composer.list_threat_agents(socket.assigns.workspace_id))
     |> broadcast_workspace_update()}
  end

  @impl true
  def handle_info({:selected_label_dropdown, id, "td_level", value}, socket) do
    threat_agent_id = String.replace_prefix(id, "threat-agent-td-level-", "")

    case Composer.update_threat_agent(Composer.get_threat_agent!(threat_agent_id), %{
           "td_level" => value
         }) do
      {:ok, _threat_agent} ->
        {:noreply,
         assign(socket, :threat_agents, Composer.list_threat_agents(socket.assigns.workspace_id))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update Threat Agent"))}
    end
  end

  @impl true
  def handle_info(%{topic: "workspace_" <> workspace_id}, socket) do
    {:noreply, assign(socket, :threat_agents, Composer.list_threat_agents(workspace_id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Composer.get_threat_agent!(id) do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("Threat Agent not found"))}

      threat_agent ->
        case Composer.delete_threat_agent(threat_agent) do
          {:ok, _deleted} ->
            log(
              :info,
              socket.assigns.current_user,
              "Deleted threat agent",
              %{workspace_id: socket.assigns.workspace_id, threat_agent_id: id},
              "threat_agent"
            )

            {:noreply,
             socket
             |> put_flash(:info, gettext("Threat Agent deleted successfully"))
             |> assign(
               :threat_agents,
               Composer.list_threat_agents(socket.assigns.workspace_id)
             )
             |> broadcast_workspace_update()}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, gettext("Failed to delete Threat Agent"))}
        end
    end
  end

  def display_tag_value(nil), do: gettext("Not set")
  def display_tag_value(""), do: gettext("Not set")
  def display_tag_value(value), do: value |> to_string() |> Phoenix.Naming.humanize()

  def display_td_level(nil), do: gettext("Not set")

  def display_td_level(value),
    do: Composer.DeliberateThreatLevel.label(value) || gettext("Not set")

  def td_level_items do
    Enum.map(Composer.DeliberateThreatLevel.values(), &{&1, nil})
  end

  defp broadcast_workspace_update(socket) do
    ValentineWeb.Endpoint.broadcast!(
      "workspace_" <> socket.assigns.workspace_id,
      "workspace_updated",
      %{}
    )

    socket
  end

  defp get_workspace(id) do
    Composer.get_workspace!(id, [:threat_agents])
  end
end
