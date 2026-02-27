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
    {:ok,
     socket
     |> assign(:tabs, assigns[:tabs] || [])
     |> assign(:current_tab, assigns[:current_tab] || List.first(assigns[:tabs] || [])[:id])
     |> assign(:tab_content, assigns[:tab_content] || %{})}
  end

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
    {:noreply, assign(socket, :current_tab, tab_id)}
  end
end
