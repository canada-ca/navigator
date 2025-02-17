defmodule ValentineWeb.WorkspaceLive.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Workspace

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:workspaces, Composer.list_workspaces())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"workspace_id" => workspace_id}) do
    socket
    |> assign(:page_title, gettext("Edit Workspace"))
    |> assign(:workspace, Composer.get_workspace!(workspace_id))
  end

  defp apply_action(socket, :import, _params) do
    socket
    |> assign(:page_title, gettext("Import Workspace"))
    |> assign(:workspace, %Workspace{})
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Workspace"))
    |> assign(:workspace, %Workspace{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Workspaces"))
    |> assign(:workspace, nil)
  end

  @impl true
  def handle_event("delete", %{"workspace_id" => workspace_id}, socket) do
    workspace = Composer.get_workspace!(workspace_id)

    case Composer.delete_workspace(workspace) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Workspace deleted successfully"))
         |> assign(
           :workspaces,
           Composer.list_workspaces()
         )}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, gettext("Failed to delete workspace"))}
    end
  end

  @impl true
  def handle_info({ValentineWeb.WorkspaceLive.FormComponent, {:saved, _workspace}}, socket) do
    {:noreply, assign(socket, :workspaces, Composer.list_workspaces())}
  end
end
