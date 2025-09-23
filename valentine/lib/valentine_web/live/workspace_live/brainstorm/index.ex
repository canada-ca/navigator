defmodule ValentineWeb.WorkspaceLive.Brainstorm.Index do
  use ValentineWeb, :live_view
  use PrimerLive
  require Logger

  alias Valentine.Composer
  alias Valentine.Composer.BrainstormItem
  alias Phoenix.PubSub

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = Composer.get_workspace!(workspace_id)

    # Subscribe to workspace-specific brainstorm updates
    if connected?(socket) do
      PubSub.subscribe(Valentine.PubSub, "brainstorm:workspace:#{workspace.id}")
    end

    # Load brainstorm items grouped by type
    items_by_type = Composer.list_brainstorm_items_by_type(workspace_id)

    # Initialize filters
    filters = %{
      status: nil,
      type: nil,
      cluster: nil,
      search: ""
    }

    # Calculate total items for empty state
    total_items =
      items_by_type
      |> Map.values()
      |> List.flatten()
      |> length()

    # Initial type order (alphabetical by populated types)
    type_order =
      items_by_type
      |> Map.keys()
      |> Enum.sort()

    {:ok,
     socket
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)
     |> assign(:items_by_type, items_by_type)
     |> assign(:total_items, total_items)
     |> assign(:filters, filters)
     |> assign(:undo_queue, [])
     |> assign(:editing_item, nil)
     |> assign(:assigning_cluster_item, nil)
     |> assign(:type_order, type_order)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Brainstorm Board"))
  end

  # Create new brainstorm item
  @impl true
  def handle_event("create_item", %{"type" => type, "text" => text}, socket) when type != "" do
    attrs = %{
      workspace_id: socket.assigns.workspace_id,
      type: String.to_existing_atom(type),
      raw_text: text
    }

    case Composer.create_brainstorm_item(attrs) do
      {:ok, item} ->
        broadcast_update(socket.assigns.workspace_id, :item_created, item)

        {:noreply,
         socket
         |> refresh_items()}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create item: #{format_errors(changeset)}")}
    end
  end

  def handle_event("create_item", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:error, gettext("Please select a category for your item"))}
  end

  # Update existing brainstorm item
  @impl true
  def handle_event("update_item", %{"item_id" => id, "text" => text, "type" => type}, socket) do
    item = Composer.get_brainstorm_item!(id)

    update_attrs = %{raw_text: text}

    update_attrs =
      if type && type != Atom.to_string(item.type) do
        Map.put(update_attrs, :type, String.to_existing_atom(type))
      else
        update_attrs
      end

    case Composer.update_brainstorm_item(item, update_attrs) do
      {:ok, updated_item} ->
        broadcast_update(socket.assigns.workspace_id, :item_updated, updated_item)

        {:noreply,
         socket
         |> refresh_items()
         |> assign(:editing_item, nil)
         |> put_flash(:info, gettext("Item updated successfully"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update item: #{format_errors(changeset)}")}
    end
  end

  def handle_event("update_item", %{"item_id" => id, "text" => text}, socket) do
    item = Composer.get_brainstorm_item!(id)

    case Composer.update_brainstorm_item(item, %{raw_text: text}) do
      {:ok, updated_item} ->
        broadcast_update(socket.assigns.workspace_id, :item_updated, updated_item)

        {:noreply,
         socket
         |> refresh_items()
         |> assign(:editing_item, nil)
         |> put_flash(:info, gettext("Item updated successfully"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update item: #{format_errors(changeset)}")}
    end
  end

  # Delete brainstorm item with undo capability
  @impl true
  def handle_event("delete_item", %{"id" => id}, socket) do
    item = Composer.get_brainstorm_item!(id)

    case Composer.delete_brainstorm_item(item) do
      {:ok, deleted_item} ->
        # Add to undo queue with timestamp
        undo_entry = %{
          item: deleted_item,
          timestamp: System.monotonic_time(:second)
        }

        undo_queue = [undo_entry | socket.assigns.undo_queue]

        # Schedule cleanup of old undo entries
        Process.send_after(self(), :cleanup_undo_queue, 10_000)

        broadcast_update(socket.assigns.workspace_id, :item_deleted, deleted_item)

        {:noreply,
         socket
         |> refresh_items()
         |> assign(:undo_queue, undo_queue)
         |> put_flash(:info, gettext("Item deleted. Undo available."))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete item"))}
    end
  end

  # Undo delete
  @impl true
  def handle_event("undo_delete", %{"id" => id}, socket) do
    case find_undo_entry(socket.assigns.undo_queue, id) do
      {entry, remaining_queue} ->
        case Composer.create_brainstorm_item(
               entry.item
               |> Map.from_struct()
               |> Map.drop([:__meta__, :workspace, :id, :inserted_at, :updated_at])
             ) do
          {:ok, restored_item} ->
            broadcast_update(socket.assigns.workspace_id, :item_created, restored_item)

            {:noreply,
             socket
             |> refresh_items()
             |> assign(:undo_queue, remaining_queue)
             |> put_flash(:info, gettext("Item restored successfully"))}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, gettext("Failed to restore item"))}
        end

      nil ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Item no longer available for undo"))}
    end
  end

  # Update item status
  @impl true
  def handle_event("update_status", %{"id" => id, "status" => status}, socket) do
    item = Composer.get_brainstorm_item!(id)

    case Composer.update_brainstorm_item(item, %{status: String.to_existing_atom(status)}) do
      {:ok, updated_item} ->
        broadcast_update(socket.assigns.workspace_id, :item_updated, updated_item)

        {:noreply,
         socket
         |> refresh_items()
         |> put_flash(:info, gettext("Status updated successfully"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update status: #{format_errors(changeset)}")}
    end
  end

  # Drag & drop move between categories (types)
  @impl true
  def handle_event("move_item", %{"id" => id, "type" => new_type}, socket) do
    item = Composer.get_brainstorm_item!(id)

    cond do
      new_type == Atom.to_string(item.type) ->
        # No change
        {:noreply, socket}

      true ->
        case Composer.update_brainstorm_item(item, %{type: String.to_existing_atom(new_type)}) do
          {:ok, updated_item} ->
            broadcast_update(socket.assigns.workspace_id, :item_updated, updated_item)
            {:noreply, refresh_items(socket)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, gettext("Failed to move item"))}
        end
    end
  end

  # Reorder the visible types (columns/cards)
  @impl true
  def handle_event("reorder_types", %{"order" => order_list}, socket) when is_list(order_list) do
    # Sanitize: keep only existing populated types, convert to atoms
    existing_types = Map.keys(socket.assigns.items_by_type) |> MapSet.new()

    new_order =
      order_list
      |> Enum.map(fn t ->
        try do
          String.to_existing_atom(t)
        rescue
          ArgumentError -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(&MapSet.member?(existing_types, &1))

    # Append any remaining types that may have been added concurrently
    remaining =
      existing_types
      |> Enum.reject(&(&1 in new_order))

    final_order = new_order ++ remaining

    broadcast_types_reordered(socket.assigns.workspace_id, final_order)

    {:noreply, assign(socket, :type_order, final_order)}
  end

  def handle_event("reorder_types", _params, socket), do: {:noreply, socket}

  # Assign item to cluster
  @impl true
  def handle_event("start_cluster_assign", %{"id" => id}, socket) do
    item = Composer.get_brainstorm_item!(id)
    clusters = Composer.list_clusters_by_type(socket.assigns.workspace_id, item.type)

    {:noreply,
     socket
     |> assign(:assigning_cluster_item, id)
     |> assign(:cluster_assignment_type, item.type)
     |> assign(:available_clusters, clusters)
     |> assign(:cluster_mode, if(Enum.empty?(clusters), do: :new, else: :existing))}
  end

  @impl true
  def handle_event("cancel_cluster_assign", _params, socket) do
    {:noreply,
     socket
     |> assign(:assigning_cluster_item, nil)
     |> assign(:available_clusters, [])
     |> assign(:cluster_mode, nil)
     |> assign(:cluster_assignment_type, nil)}
  end

  @impl true
  def handle_event("assign_cluster", params = %{"id" => id}, socket) do
    item = Composer.get_brainstorm_item!(id)

    cluster_key =
      cond do
        Map.get(params, "existing_cluster") && params["existing_cluster"] != "" ->
          params["existing_cluster"]

        Map.get(params, "new_cluster") && String.trim(params["new_cluster"]) != "" ->
          String.trim(params["new_cluster"])

        Map.get(params, "cluster") && params["cluster"] != "" ->
          # backwards compatibility with old form field name
          params["cluster"]

        true ->
          nil
      end

    case Composer.assign_to_cluster(item, cluster_key) do
      {:ok, updated_item} ->
        broadcast_update(socket.assigns.workspace_id, :item_updated, updated_item)

        {:noreply,
         socket
         |> assign(:assigning_cluster_item, nil)
         |> assign(:available_clusters, [])
         |> assign(:cluster_mode, nil)
         |> assign(:cluster_assignment_type, nil)
         |> refresh_items()
         |> put_flash(:info, gettext("Item assigned to cluster"))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to assign cluster"))}
    end
  end

  # Toggle UI states
  @impl true
  def handle_event("start_editing", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_item, id)}
  end

  @impl true
  def handle_event("cancel_editing", _params, socket) do
    {:noreply, assign(socket, :editing_item, nil)}
  end

  # Fallback for direct parameter events
  def handle_event("filter", params, socket) do
    current_filters = socket.assigns.filters

    updated_filters =
      cond do
        Map.has_key?(params, "search") ->
          %{current_filters | search: params["search"] || ""}

        Map.has_key?(params, "filter_status") ->
          %{current_filters | status: normalize_filter_value(params["filter_status"])}

        Map.has_key?(params, "filter_type") ->
          %{current_filters | type: normalize_filter_value(params["filter_type"])}

        true ->
          current_filters
      end

    {:noreply,
     socket
     |> assign(:filters, updated_filters)
     |> refresh_items()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{status: nil, type: nil, cluster: nil, search: ""}

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> refresh_items()}
  end

  # Handle real-time updates from other users
  @impl true
  def handle_info({:item_created, _item}, socket) do
    {:noreply, refresh_items(socket)}
  end

  def handle_info({:item_updated, _item}, socket) do
    {:noreply, refresh_items(socket)}
  end

  def handle_info({:item_deleted, _item}, socket) do
    {:noreply, refresh_items(socket)}
  end

  def handle_info({:types_reordered, order}, socket) do
    {:noreply, assign(socket, :type_order, order)}
  end

  # Clean up old undo entries
  @impl true
  def handle_info(:cleanup_undo_queue, socket) do
    current_time = System.monotonic_time(:second)

    undo_queue =
      Enum.filter(socket.assigns.undo_queue, fn entry ->
        current_time - entry.timestamp < 10
      end)

    {:noreply, assign(socket, :undo_queue, undo_queue)}
  end

  # Private helper functions

  defp refresh_items(socket) do
    # Apply filters and refresh items
    filters = socket.assigns.filters
    workspace_id = socket.assigns.workspace_id

    base_filters =
      %{}
      |> maybe_add_filter(:status, filters.status)
      |> maybe_add_filter(:type, filters.type)

    items = Composer.list_brainstorm_items(workspace_id, base_filters)

    # Apply search filter client-side for now
    items =
      if filters.search != "" do
        search_term = String.downcase(filters.search)

        Enum.filter(items, fn item ->
          String.contains?(String.downcase(item.raw_text), search_term) or
            (item.cluster_key && String.contains?(String.downcase(item.cluster_key), search_term))
        end)
      else
        items
      end

    # Group by type
    items_by_type = Enum.group_by(items, & &1.type)

    # Calculate total items
    total_items = length(items)

    # Reconcile existing type order (remove missing, append new)
    type_order = socket.assigns[:type_order] || []
    current_types = Map.keys(items_by_type) |> Enum.sort()

    preserved = Enum.filter(type_order, &(&1 in current_types))
    new_types = current_types -- preserved
    reconciled_order = preserved ++ new_types

    socket
    |> assign(:items_by_type, items_by_type)
    |> assign(:total_items, total_items)
    |> assign(:type_order, reconciled_order)
  end

  defp maybe_add_filter(filters, _key, nil), do: filters
  defp maybe_add_filter(filters, _key, ""), do: filters
  defp maybe_add_filter(filters, key, value), do: Map.put(filters, key, value)

  defp normalize_filter_value(""), do: nil
  defp normalize_filter_value(nil), do: nil

  defp normalize_filter_value(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> nil
    end
  end

  defp normalize_filter_value(value), do: value

  defp broadcast_update(workspace_id, event, item) do
    PubSub.broadcast(Valentine.PubSub, "brainstorm:workspace:#{workspace_id}", {event, item})
  end

  defp broadcast_types_reordered(workspace_id, order) do
    PubSub.broadcast(
      Valentine.PubSub,
      "brainstorm:workspace:#{workspace_id}",
      {:types_reordered, order}
    )
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  defp find_undo_entry(undo_queue, id) do
    Enum.find_value(undo_queue, fn entry ->
      if entry.item.id == id do
        remaining = Enum.reject(undo_queue, &(&1.item.id == id))
        {entry, remaining}
      end
    end)
  end

  # Get available types for column display
  defp get_available_types do
    Ecto.Enum.values(BrainstormItem, :type)
  end

  # Visible types: hide types whose items are all archived unless filtering to archived
  defp ordered_visible_types(items_by_type, order, filters) do
    populated_visible =
      items_by_type
      |> Enum.filter(fn {_type, items} ->
        if filters.status == :archived do
          true
        else
          Enum.any?(items, &(&1.status != :archived))
        end
      end)
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()

    ordered = Enum.filter(order, &MapSet.member?(populated_visible, &1))
    remainder = Enum.reject(populated_visible, &(&1 in ordered)) |> Enum.sort()
    ordered ++ remainder
  end

  # Get visible items after applying filters
  defp get_visible_items(items, filters) do
    items
    |> Enum.reject(&(&1.status == :archived and filters.status != :archived))
  end

  # Group items by cluster for display
  defp group_by_cluster(items) do
    {clustered, unclustered} = Enum.split_with(items, &(&1.cluster_key != nil))

    clustered_groups =
      clustered
      |> Enum.group_by(& &1.cluster_key)
      |> Enum.sort_by(fn {cluster_key, _} -> cluster_key end)
      |> Enum.flat_map(fn {cluster_key, cluster_items} ->
        [cluster_key | cluster_items]
      end)

    clustered_groups ++ unclustered
  end

  # Get type display name
  defp type_display_name(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  # Get appropriate icon for each type
  defp type_icon(:threat), do: "alert-16"
  defp type_icon(:assumption), do: "info-16"
  defp type_icon(:mitigation), do: "shield-16"
  defp type_icon(:evidence), do: "file-16"
  defp type_icon(:requirement), do: "checklist-16"
  defp type_icon(:asset), do: "package-16"
  defp type_icon(:component), do: "server-16"
  defp type_icon(:attack_vector), do: "zap-16"
  defp type_icon(:vulnerability), do: "bug-16"
  defp type_icon(:impact), do: "flame-16"
  defp type_icon(:control), do: "lock-16"
  defp type_icon(:risk), do: "issue-opened-16"
  defp type_icon(:stakeholder), do: "person-16"
  defp type_icon(:boundary), do: "square-16"
  defp type_icon(:trust_zone), do: "shield-check-16"
  defp type_icon(:data_flow), do: "arrow-right-16"
  defp type_icon(:process), do: "gear-16"
  defp type_icon(:data_store), do: "database-16"
  defp type_icon(:external_entity), do: "globe-16"
  defp type_icon(_), do: "circle-16"

  # Status color classes for labels
  defp status_color_class(:draft), do: "Label--accent"
  defp status_color_class(:clustered), do: "Label--attention"
  defp status_color_class(:candidate), do: "Label--success"
  defp status_color_class(:used), do: "Label--done"
  defp status_color_class(:archived), do: "Label--secondary"
end
