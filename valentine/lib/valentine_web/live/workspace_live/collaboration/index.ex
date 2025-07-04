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
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:permission, socket.assigns.workspace_permission)
     |> assign(:users, users)
     |> assign(:workspace, workspace)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Collaboration"))
  end

  @impl true
  def handle_event("update_permission", %{"email" => email, "permission" => permission}, socket) do
    if socket.assigns.workspace_permission == "owner" do
      log(
        :info,
        socket.assigns.current_user,
        permission,
        %{workspace: socket.assigns.workspace.id, collaborator: email},
        "collaboration"
      )

      {:ok, workspace} =
        Composer.update_workspace_permissions(socket.assigns.workspace, email, permission)

      {:noreply,
       socket
       |> assign(:workspace, workspace)}
    else
      {:noreply, socket}
    end
  end
end
