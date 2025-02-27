defmodule ValentineWeb.WorkspaceLive.Components.DrawerComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  def mount(socket) do
    {:ok, socket |> assign(open_drawer: false) |> assign(count: 0) |> assign(button: [])}
  end

  def handle_event("toggle_drawer", _params, socket) do
    {:noreply, socket |> assign(open_drawer: !socket.assigns.open_drawer)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box class="p-2 my-4">
        <div class="clearfix">
          <h3 phx-click="toggle_drawer" phx-target={@myself} class="float-left">
            <.button is_icon_only>
              <%= if @open_drawer do %>
                <.octicon name="chevron-down-24" />
              <% else %>
                <.octicon name="chevron-right-24" />
              <% end %>
            </.button>
            {@title}
            <%= if @count > 0 do %>
              <span class="text-gray-500">({@count})</span>
            <% end %>
          </h3>
          <div class="float-right">
            {render_slot(@button)}
          </div>
        </div>
        <%= if @open_drawer do %>
          {render_slot(@content)}
        <% end %>
      </.box>
    </div>
    """
  end
end
