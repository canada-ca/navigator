defmodule ValentineWeb.WorkspaceLive.ReferencePacks.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)

    {:ok,
     socket
     |> assign(:reference_packs, Composer.list_reference_packs())
     |> assign(:workspace, workspace)}
  end

  @impl true
  def handle_event("delete", %{"id" => collection_id, "type" => collection_type}, socket) do
    Composer.delete_reference_pack_collection(collection_id, collection_type)

    log(
      :info,
      socket.assigns.current_user,
      "delete",
      %{workspace: socket.assigns.workspace_id, collection: collection_id},
      "reference_pack"
    )

    {:noreply,
     socket
     |> put_flash(:info, gettext("Reference pack deleted successfully"))
     |> assign(:reference_packs, Composer.list_reference_packs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :import, _params) do
    socket
    |> assign(:page_title, gettext("Import reference pack"))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Reference packs"))
  end

  defp get_workspace(id) do
    Composer.get_workspace!(id)
  end
end
