defmodule ValentineWeb.WorkspaceLive.ThreatModel.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)

    {:ok,
     socket
     |> assign(:workspace, workspace)
     |> assign(:assumptions, workspace.assumptions)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, gettext("Threat model"))
    |> assign(:auto_print, params["print"] == "true")
  end

  defp get_workspace(id) do
    Composer.get_workspace!(id, [
      :application_information,
      :architecture,
      :data_flow_diagram,
      :threat_agents,
      mitigations: [:assumptions, :threats],
      threats: [:assumptions, :mitigations],
      assumptions: [:threats, :mitigations]
    ])
  end
end
