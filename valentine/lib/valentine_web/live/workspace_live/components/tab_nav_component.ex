defmodule ValentineWeb.WorkspaceLive.Components.TabNavComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  def mount(socket) do
    {:ok,
     socket
     |> assign(:tabs, [])
     |> assign(:current_tab, "")}
  end

  def update(assigns, socket) do
    tabs = assigns[:tabs] || []

    # Get first tab ID safely
    first_tab_id =
      case tabs do
        [%{id: id} | _] -> id
        _ -> ""
      end

    # Preserve component state with proper validation
    # Priority: explicit parent override > existing valid state > default to first tab
    current_tab =
      cond do
        valid_tab_id?(Map.get(assigns, :current_tab), tabs) ->
          Map.get(assigns, :current_tab)

        valid_tab_id?(Map.get(socket.assigns, :current_tab), tabs) ->
          Map.get(socket.assigns, :current_tab)

        true ->
          first_tab_id
      end

    {:ok,
     socket
     |> assign(:tabs, tabs)
     |> assign(:current_tab, current_tab)
     |> assign(:tab_content, assigns[:tab_content] || %{})}
  end

  defp valid_tab_id?(tab_id, tabs) when is_binary(tab_id) and tab_id != "" do
    Enum.any?(tabs, fn %{id: id} -> id == tab_id end)
  end

  defp valid_tab_id?(_, _), do: false

  def render(assigns) do
    ~H"""
    <div class="mt-2 tabnav-container">
      <.tabnav class="mb-0">
        <:item
          :for={%{label: label, id: id} <- @tabs}
          is_selected={id == @current_tab}
          phx-value-item={id}
          phx-click="set_tab"
          phx-target={@myself}
          type="button"
        >
          {label}
        </:item>
      </.tabnav>
      <.box class="p-2" style="border-top:0px; border-radius:0;">
        {render_slot(@tab_content, @current_tab)}
      </.box>
    </div>
    """
  end

  def handle_event("set_tab", %{"item" => tab_id}, socket) do
    if valid_tab_id?(tab_id, socket.assigns.tabs) do
      {:noreply, assign(socket, :current_tab, tab_id)}
    else
      {:noreply, socket}
    end
  end
end
