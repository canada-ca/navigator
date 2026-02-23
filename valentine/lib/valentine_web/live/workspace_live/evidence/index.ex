defmodule ValentineWeb.WorkspaceLive.Evidence.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  import Ecto.Query
  alias Valentine.Repo
  alias Valentine.Composer
  alias Valentine.Composer.Evidence

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)
    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace.id)

    evidence = get_evidence_list(workspace_id)

    {:ok,
     socket
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)
     |> assign(:filters, %{})
     |> assign(:evidence, evidence)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Evidence Overview"))
  end

  defp apply_action(socket, :assumptions, %{"id" => evidence_id}) do
    evidence_item = Composer.get_evidence!(evidence_id, [:assumptions])

    socket
    |> assign(:page_title, gettext("Link Evidence"))
    |> assign(:evidence_item, evidence_item)
    |> assign(:source_entity_type, :evidence)
    |> assign(:target_entity_type, :assumptions)
    |> assign(:linkable_entities, socket.assigns.workspace.assumptions)
    |> assign(:linked_entities, evidence_item.assumptions)
  end

  defp apply_action(socket, :threats, %{"id" => evidence_id}) do
    evidence_item = Composer.get_evidence!(evidence_id, [:threats])

    socket
    |> assign(:page_title, gettext("Link Evidence"))
    |> assign(:evidence_item, evidence_item)
    |> assign(:source_entity_type, :evidence)
    |> assign(:target_entity_type, :threats)
    |> assign(:linkable_entities, socket.assigns.workspace.threats)
    |> assign(:linked_entities, evidence_item.threats)
  end

  defp apply_action(socket, :mitigations, %{"id" => evidence_id}) do
    evidence_item = Composer.get_evidence!(evidence_id, [:mitigations])

    socket
    |> assign(:page_title, gettext("Link Evidence"))
    |> assign(:evidence_item, evidence_item)
    |> assign(:source_entity_type, :evidence)
    |> assign(:target_entity_type, :mitigations)
    |> assign(:linkable_entities, socket.assigns.workspace.mitigations)
    |> assign(:linked_entities, evidence_item.mitigations)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Composer.get_evidence!(id) do
      nil ->
        {:noreply, socket |> put_flash(:error, gettext("Evidence not found"))}

      evidence ->
        case Composer.delete_evidence(evidence) do
          {:ok, _} ->
            log(
              :info,
              socket.assigns.current_user,
              "delete",
              %{evidence: evidence.id, workspace: evidence.workspace_id},
              "evidence"
            )

            {:noreply,
             socket
             |> put_flash(:info, gettext("Evidence deleted successfully"))
             |> assign(:evidence, get_evidence_list(socket.assigns.workspace_id))}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, gettext("Failed to delete evidence"))}
        end
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign(:evidence, get_evidence_list(socket.assigns.workspace_id))}
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:evidence, get_filtered_evidence_list(socket.assigns.workspace_id, filters))}
  end

  @impl true
  def handle_info(
        {ValentineWeb.WorkspaceLive.Components.EntityLinkerComponent, {:saved, _entity}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:evidence, get_evidence_list(socket.assigns.workspace_id))
     |> push_patch(to: ~p"/workspaces/#{socket.assigns.workspace_id}/evidence")}
  end

  defp get_evidence_list(workspace_id) do
    from(e in Evidence,
      where: e.workspace_id == ^workspace_id,
      preload: [:assumptions, :threats, :mitigations],
      order_by: [desc: e.inserted_at]
    )
    |> Valentine.Repo.all()
  end

  defp get_filtered_evidence_list(workspace_id, filters) do
    base_query =
      from(e in Evidence,
        where: e.workspace_id == ^workspace_id,
        preload: [:assumptions, :threats, :mitigations],
        order_by: [desc: e.inserted_at]
      )

    apply_filters(base_query, filters)
    |> Valentine.Repo.all()
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn {key, values}, acc_query ->
      case key do
        :evidence_type when is_list(values) and length(values) > 0 ->
          from(e in acc_query, where: e.evidence_type in ^values)

        :tags when is_list(values) and length(values) > 0 ->
          from(e in acc_query, where: fragment("? && ?", e.tags, ^values))

        :nist_controls when is_list(values) and length(values) > 0 ->
          from(e in acc_query, where: fragment("? && ?", e.nist_controls, ^values))

        _ ->
          acc_query
      end
    end)
  end

  defp get_workspace(id) do
    Composer.get_workspace!(id, [:evidence, :assumptions, :threats, :mitigations])
  end

  defp format_evidence_type(:json_data), do: "JSON Data"
  defp format_evidence_type(:blob_store_link), do: "File Link"
  defp format_evidence_type(type), do: to_string(type) |> String.capitalize()

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end

  defp get_all_tags(evidence_list) when is_list(evidence_list) and length(evidence_list) > 0 do
    evidence_list
    |> Enum.flat_map(& &1.tags)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp get_all_tags(_), do: []

  defp get_all_nist_controls(evidence_list)
       when is_list(evidence_list) and length(evidence_list) > 0 do
    evidence_list
    |> Enum.flat_map(& &1.nist_controls)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp get_all_nist_controls(_), do: []
end
