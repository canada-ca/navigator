defmodule ValentineWeb.WorkspaceLive.Evidence.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  import Ecto.Query
  alias Valentine.Composer
  alias Valentine.Composer.Evidence

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)
    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace.id)

    {:ok,
     socket
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)
     |> assign(:filters, %{})
     |> assign(:sort_by, :inserted_at)
     |> assign(:sort_order, :desc)
     |> assign(:page, 1)
     |> assign(:page_size, 10)
     |> assign(
       :evidence_list,
       get_evidence_list(workspace_id, %{}, :inserted_at, :desc, 1, 10)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Evidence Overview"))
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
             |> assign(
               :evidence_list,
               get_evidence_list(
                 socket.assigns.workspace_id,
                 socket.assigns.filters,
                 socket.assigns.sort_by,
                 socket.assigns.sort_order,
                 socket.assigns.page,
                 socket.assigns.page_size
               )
             )}

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
     |> assign(:page, 1)
     |> assign(
       :evidence_list,
       get_evidence_list(
         socket.assigns.workspace_id,
         %{},
         socket.assigns.sort_by,
         socket.assigns.sort_order,
         1,
         socket.assigns.page_size
       )
     )}
  end

  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    sort_by_atom = String.to_existing_atom(sort_by)

    sort_order =
      if socket.assigns.sort_by == sort_by_atom and socket.assigns.sort_order == :asc,
        do: :desc,
        else: :asc

    {:noreply,
     socket
     |> assign(:sort_by, sort_by_atom)
     |> assign(:sort_order, sort_order)
     |> assign(:page, 1)
     |> assign(
       :evidence_list,
       get_evidence_list(
         socket.assigns.workspace_id,
         socket.assigns.filters,
         sort_by_atom,
         sort_order,
         1,
         socket.assigns.page_size
       )
     )}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    page = String.to_integer(page)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(
       :evidence_list,
       get_evidence_list(
         socket.assigns.workspace_id,
         socket.assigns.filters,
         socket.assigns.sort_by,
         socket.assigns.sort_order,
         page,
         socket.assigns.page_size
       )
     )}
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    {
      :noreply,
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(
        :evidence_list,
        get_evidence_list(
          socket.assigns.workspace_id,
          filters,
          socket.assigns.sort_by,
          socket.assigns.sort_order,
          1,
          socket.assigns.page_size
        )
      )
    }
  end

  defp get_evidence_list(workspace_id, filters, sort_by, sort_order, page, page_size) do
    offset = (page - 1) * page_size

    evidence_query =
      from(e in Evidence,
        where: e.workspace_id == ^workspace_id,
        preload: [:assumptions, :threats, :mitigations],
        order_by: [{^sort_order, ^sort_by}],
        limit: ^page_size,
        offset: ^offset
      )

    evidence_query = apply_filters(evidence_query, filters)

    %{
      evidence: Valentine.Repo.all(evidence_query),
      total_count: get_total_count(workspace_id, filters),
      current_page: page,
      page_size: page_size,
      total_pages: ceil(get_total_count(workspace_id, filters) / page_size)
    }
  end

  defp get_total_count(workspace_id, filters) do
    count_query = from(e in Evidence, where: e.workspace_id == ^workspace_id)
    count_query = apply_filters(count_query, filters)
    Valentine.Repo.aggregate(count_query, :count, :id)
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
    Composer.get_workspace!(id, [:evidence])
  end

  defp format_evidence_type(:json_data), do: "JSON Data"
  defp format_evidence_type(:blob_store_link), do: "File Link"
  defp format_evidence_type(type), do: to_string(type) |> String.capitalize()

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end

  defp sort_indicator(current_sort, target_sort, sort_order) do
    if current_sort == target_sort do
      case sort_order do
        :asc -> "↑"
        :desc -> "↓"
      end
    else
      ""
    end
  end

  defp get_all_tags(evidence_list) when is_list(evidence_list) and length(evidence_list) > 0 do
    evidence_list
    |> Enum.flat_map(& &1.tags)
    |> Enum.uniq()
    |> Enum.sort()
  end
  defp get_all_tags(_), do: []

  defp get_all_nist_controls(evidence_list) when is_list(evidence_list) and length(evidence_list) > 0 do
    evidence_list
    |> Enum.flat_map(& &1.nist_controls)
    |> Enum.uniq()
    |> Enum.sort()
  end
  defp get_all_nist_controls(_), do: []
end
