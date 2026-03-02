defmodule ValentineWeb.WorkspaceLive.Components.FilterComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  @impl true
  def render(assigns) do
    assigns =
      if !Map.has_key?(assigns.filters, assigns.name) do
        assign(assigns, :filters, Map.put(assigns.filters, assigns.name, []))
      else
        # Filter any values that are not in the list of atomic values
        assign(
          assigns,
          :filters,
          Map.update!(assigns.filters, assigns.name, fn values ->
            Enum.filter(values, &(&1 in assigns.values))
          end)
        )
      end

    ~H"""
    <div class={@class}>
      <.action_menu is_dropdown_caret id={"#{@id}-dropdown"}>
        <:toggle>
          <.octicon name={"#{@icon}-16"} />
          <span>
            {Gettext.gettext(ValentineWeb.Gettext, Phoenix.Naming.humanize(@name))}
          </span>
          <%= if is_list(@filters[@name]) && length(@filters[@name]) > 0 do %>
            <.counter>
              {length(@filters[@name])}
            </.counter>
          <% end %>
        </:toggle>
        <.action_list is_multiple_select>
          <.action_list_item is_inline_description phx-click="clear_filter" phx-target={@myself}>
            <:description><.octicon name="x-16" />{gettext("Clear all")}</:description>
          </.action_list_item>
          <.action_list_section_divider />
          <%= for value <- @values do %>
            <.action_list_item
              field={@name}
              checked_value={value}
              is_selected={value in @filters[@name]}
              is_multiple_select
              phx-click="select_filter"
              phx-target={@myself}
              phx-value-checked={value}
            >
              {Gettext.gettext(ValentineWeb.Gettext, display_label(assigns, value))}
            </.action_list_item>
          <% end %>
        </.action_list>
      </.action_menu>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    atomic_values =
      case hd(assigns[:values]) do
        atom when is_atom(atom) -> true
        _ -> false
      end

    {:ok, socket |> assign(assigns) |> assign(:atomic_values, atomic_values)}
  end

  @impl true
  def handle_event("clear_filter", _params, socket) do
    %{filters: filters, name: name} = socket.assigns
    filters = Map.delete(filters, name)
    send(self(), {:update_filter, filters})
    {:noreply, assign(socket, filters: filters)}
  end

  @impl true
  def handle_event("select_filter", params, socket) do
    %{filters: filters, name: name} = socket.assigns

    value =
      if socket.assigns.atomic_values do
        String.to_existing_atom(params["checked"])
      else
        params["checked"]
      end

    filters =
      cond do
        !filters[name] ->
          Map.put(filters, name, [value])

        value in filters[name] ->
          filters =
            Map.update!(filters, name, fn values ->
              Enum.reject(values, &(&1 == value))
            end)

          if length(filters[name]) == 0 do
            Map.delete(filters, name)
          else
            filters
          end

        true ->
          Map.update!(filters, name, fn values ->
            [value | values]
          end)
      end

    send(self(), {:update_filter, filters})
    {:noreply, assign(socket, filters: filters)}
  end

  defp display_label(assigns, value) do
    case Map.get(assigns, :labels) do
      nil -> humanize(value)
      labels when is_map(labels) -> Map.get(labels, value, humanize(value))
    end
  end

  defp humanize(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp humanize(value) when is_binary(value), do: value
end
