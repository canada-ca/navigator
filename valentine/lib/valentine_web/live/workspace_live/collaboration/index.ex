defmodule ValentineWeb.WorkspaceLive.Collaboration.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = Composer.get_workspace!(workspace_id)
    users = Composer.list_users()

    {:ok,
     socket
     |> assign(:workspace, workspace)
     |> assign(:users, users)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Collaboration"))
  end
end
