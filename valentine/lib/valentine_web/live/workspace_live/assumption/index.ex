defmodule ValentineWeb.WorkspaceLive.Assumption.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer.Assumptions

  alias Valentine.Composer.Workspaces
  alias Valentine.Composer.Assumption

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
       :assumptions,
       get_sorted_assumptions(workspace)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Assumption"))
    |> assign(
      :assumption,
      Assumptions.get_assumption_for_workspace!(socket.assigns.workspace_id, id)
    )
  end

  defp apply_action(socket, :categorize, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Categorize Assumption"))
    |> assign(
      :assumption,
      Assumptions.get_assumption_for_workspace!(
        socket.assigns.workspace_id,
        id,
        [:mitigations, :threats]
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      :page_title,
      "New Assumption"
    )
    |> assign(:assumption, %Assumption{workspace_id: socket.assigns.workspace_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Assumptions"))
  end

  defp apply_action(socket, :mitigations, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Link mitigations to assumption"))
    |> assign(:mitigations, socket.assigns.workspace.mitigations)
    |> assign(
      :assumption,
      Assumptions.get_assumption_for_workspace!(socket.assigns.workspace_id, id, [:mitigations])
    )
  end

  defp apply_action(socket, :threats, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Link threats to assumption"))
    |> assign(:threats, socket.assigns.workspace.threats)
    |> assign(
      :assumption,
      Assumptions.get_assumption_for_workspace!(socket.assigns.workspace_id, id, [:threats])
    )
  end

  @impl true
  def handle_info(
        {_, {:saved, _assumption}},
        socket
      ) do
    workspace = get_workspace(socket.assigns.workspace_id)

    {:noreply,
     socket
     |> assign(:assumptions, get_sorted_assumptions(workspace))}
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    {
      :noreply,
      socket
      |> assign(:filters, filters)
      |> assign(
        :assumptions,
        Assumptions.list_assumptions_by_workspace(socket.assigns.workspace_id, filters)
      )
    }
  end

  @impl true
  def handle_info(%{topic: "workspace_" <> workspace_id}, socket) do
    workspace = get_workspace(workspace_id)

    {:noreply,
     socket
     |> assign(:assumptions, get_sorted_assumptions(workspace))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Assumptions.get_assumption_for_workspace(socket.assigns.workspace_id, id) do
      nil ->
        {:noreply, socket |> put_flash(:error, gettext("Assumption not found"))}

      assumption ->
        case Assumptions.delete_assumption(assumption) do
          {:ok, _} ->
            log(
              :info,
              socket.assigns.current_user,
              "Deleted assumption",
              %{
                workspace_id: socket.assigns.workspace_id,
                assumption_id: assumption.id
              },
              "assumption"
            )

            workspace = get_workspace(socket.assigns.workspace_id)

            {:noreply,
             socket
             |> put_flash(:info, gettext("Assumption deleted successfully"))
             |> assign(
               :assumptions,
               get_sorted_assumptions(workspace)
             )}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, gettext("Failed to delete assumption"))}
        end
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign(
       :assumptions,
       Assumptions.list_assumptions_by_workspace(socket.assigns.workspace_id, %{})
     )}
  end

  defp get_sorted_assumptions(workspace) do
    workspace.assumptions |> Enum.sort(&(&1.numeric_id >= &2.numeric_id))
  end

  defp get_workspace(id) do
    Workspaces.get_workspace!(id, [:mitigations, :threats, assumptions: [:mitigations, :threats]])
  end
end
