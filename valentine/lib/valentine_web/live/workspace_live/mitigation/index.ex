defmodule ValentineWeb.WorkspaceLive.Mitigation.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Mitigation

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)
    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace.id)

    {:ok,
     socket
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)
     |> assign(:filters, %{})
     |> assign(
       :mitigations,
       get_sorted_mitigations(workspace)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :assumptions, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Link assumptions to mitigation"))
    |> assign(:assumptions, socket.assigns.workspace.assumptions)
    |> assign(:mitigation, Composer.get_mitigation!(id, [:assumptions]))
  end

  defp apply_action(socket, :categorize, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Categorize Mitigation"))
    |> assign(:mitigation, Composer.get_mitigation!(id, [:threats]))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Mitigation"))
    |> assign(:mitigation, Composer.get_mitigation!(id))
  end

  defp apply_action(socket, :threats, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Link threats to mitigation"))
    |> assign(:threats, socket.assigns.workspace.threats)
    |> assign(:mitigation, Composer.get_mitigation!(id, [:threats]))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      :page_title,
      "New Mitigation"
    )
    |> assign(:mitigation, %Mitigation{workspace_id: socket.assigns.workspace_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Mitigations"))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Composer.get_mitigation!(id) do
      nil ->
        {:noreply, socket |> put_flash(:error, gettext("Mitigation not found"))}

      mitigation ->
        case Composer.delete_mitigation(mitigation) do
          {:ok, _} ->
            workspace = get_workspace(socket.assigns.workspace_id)

            log(
              :info,
              socket.assigns.current_user,
              "delete",
              %{mitigation: mitigation.id, workspace: mitigation.workspace_id},
              "mitigation"
            )

            {:noreply,
             socket
             |> put_flash(:info, gettext("Mitigation deleted successfully"))
             |> assign(
               :mitigations,
               get_sorted_mitigations(workspace)
             )}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, gettext("Failed to delete mitigation"))}
        end
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign(
       :mitigations,
       Composer.list_mitigations_by_workspace(socket.assigns.workspace_id, %{})
     )}
  end

  @impl true
  def handle_info(
        {_, {:saved, _mitigation}},
        socket
      ) do
    workspace = get_workspace(socket.assigns.workspace_id)

    {:noreply,
     socket
     |> assign(:mitigations, get_sorted_mitigations(workspace))}
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    {
      :noreply,
      socket
      |> assign(:filters, filters)
      |> assign(
        :mitigations,
        Composer.list_mitigations_by_workspace(socket.assigns.workspace_id, filters)
      )
    }
  end

  @impl true
  def handle_info(%{topic: "workspace_" <> workspace_id}, socket) do
    workspace = get_workspace(workspace_id)

    {:noreply,
     socket
     |> assign(:mitigations, get_sorted_mitigations(workspace))}
  end

  defp get_sorted_mitigations(workspace) do
    workspace.mitigations |> Enum.sort(&(&1.numeric_id >= &2.numeric_id))
  end

  defp get_workspace(id) do
    Composer.get_workspace!(id, [:assumptions, :threats, mitigations: [:assumptions, :threats]])
  end
end
