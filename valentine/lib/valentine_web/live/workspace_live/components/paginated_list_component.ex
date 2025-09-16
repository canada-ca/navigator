defmodule ValentineWeb.WorkspaceLive.Components.PaginatedListComponent do
  use ValentineWeb, :live_component

  use PrimerLive

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:collection, [])
     |> assign(:current_page, 1)
     |> assign(:filters, [])
     |> assign(:page_size, 10)
     |> assign(:selectable, false)
     |> assign(:selected, [])
     |> assign(:title, "")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.box id={@id}>
        <:header class="d-flex flex-items-center">
          <.button_group :if={@selectable}>
            <.button is_outline phx-click="select_all" phx-target={@myself}>
              Select all
            </.button>
            <.button is_danger phx-click="deselect_all" phx-target={@myself}>
              Deselect all
            </.button>
          </.button_group>
        </:header>
        <:header_title class="flex-auto">
          <div class="float-left mt-2 mr-2">
            {@title}
            <span :if={length(@selected) > 0} class="Counter Counter--gray">
              {length(@selected)}
            </span>
          </div>
          <div class="float-left">
            <div class="d-flex">
              {render_slot(@filters)}
            </div>
          </div>
        </:header_title>
        <:row
          :for={item <- slice_collection(assigns)}
          class="d-flex flex-items-center flex-justify-between"
        >
          <div :if={@selectable} class="mr-2 mt-1">
            <.checkbox
              id={item.id}
              name={item.id}
              value={item.id}
              checked={@selected |> Enum.member?(item.id)}
              phx-click="toggle_select"
              phx-value-id={item.id}
              phx-target={@myself}
            >
              <:label></:label>
            </.checkbox>
          </div>
          <div class="flex-1">
            {render_slot(@row, item)}
          </div>
        </:row>
      </.box>
      <ValentineWeb.WorkspaceLive.Components.PaginationComponent.pagination
        page_count={length(@collection) / @page_size + 1}
        current_page={@current_page}
        link_path={fn page_num -> page_num end}
        myself={@myself}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:current_page, 1)}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    {page, ""} = Integer.parse(page)
    {:noreply, assign(socket, :current_page, page)}
  end

  @impl true
  def handle_event("select_all", _, socket) do
    selected = socket.assigns.collection |> Enum.map(& &1.id)
    send(self(), {:selected, selected})

    {:noreply, assign(socket, :selected, selected)}
  end

  @impl true
  def handle_event("deselect_all", _, socket) do
    send(self(), {:selected, []})
    {:noreply, assign(socket, :selected, [])}
  end

  @impl true
  def handle_event("toggle_select", %{"id" => id}, socket) do
    selected = socket.assigns.selected

    selected =
      if Enum.member?(selected, id) do
        Enum.reject(selected, &(&1 == id))
      else
        [id | selected]
      end

    send(self(), {:selected, selected})

    {:noreply, assign(socket, :selected, selected)}
  end

  defp slice_collection(%{
         collection: collection,
         current_page: current_page,
         page_size: page_size
       }) do
    Enum.slice(collection, (current_page - 1) * page_size, page_size)
  end

  defp slice_collection(_), do: []
end
