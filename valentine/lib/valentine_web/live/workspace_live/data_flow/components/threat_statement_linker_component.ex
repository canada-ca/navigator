defmodule ValentineWeb.WorkspaceLive.DataFlow.Components.ThreatStatementLinkerComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Threat

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:linked_threats, [])
     |> assign(:threats, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog
        id="threat-statement-linker-modal"
        is_backdrop
        is_show
        is_wide
        on_cancel={JS.push("toggle_link_threat_statement")}
      >
        <:header_title>
          {gettext("Link threat statement")}
        </:header_title>
        <:body>
          <.live_component
            module={ValentineWeb.WorkspaceLive.Components.DropdownSelectComponent}
            id="threats-dropdown"
            name="threats"
            target={@myself}
            items={
              (@threats -- @linked_threats)
              |> Enum.map(fn t -> %{id: t.id, name: Threat.show_statement(t)} end)
            }
          />
          <div class="mt-2">
            <%= for threat <- @linked_threats || [] do %>
              <.button
                phx-click="remove_threat"
                phx-target={@myself}
                phx-value-id={threat.id}
                class="tag-button mt-2"
              >
                <span>{Threat.show_statement(threat)}</span>
                <.octicon name="x-16" />
              </.button>
            <% end %>
          </div>
        </:body>
        <:footer>
          <.button is_primary phx-click="toggle_link_threat_statement">{gettext("Close")}</.button>
        </:footer>
      </.dialog>
    </div>
    """
  end

  @impl true
  def handle_event("remove_threat", %{"id" => id}, socket) do
    send(
      self(),
      {:update_metadata,
       %{
         "id" => socket.assigns.element_id,
         "field" => "linked_threats",
         "checked" => id,
         "value" => 0
       }}
    )

    linked_threats =
      Valentine.Composer.list_threats_by_ids(
        socket.assigns.element["data"]["linked_threats"] -- [id]
      )

    {:noreply,
     socket
     |> assign(:linked_threats, linked_threats)}
  end

  @impl true
  def update(%{selected_item: %{id: id}}, socket) do
    %{element_id: element_id, element: element} = socket.assigns

    send(
      self(),
      {:update_metadata,
       %{
         "id" => element_id,
         "field" => "linked_threats",
         "checked" => id,
         "value" => 0
       }}
    )

    linked_threats =
      Valentine.Composer.list_threats_by_ids(element["data"]["linked_threats"] ++ [id])

    element = put_in(element["data"]["linked_threats"], Enum.map(linked_threats, & &1.id))

    {:ok,
     socket
     |> assign(:element, element)
     |> assign(:linked_threats, linked_threats)}
  end

  @impl true
  def update(assigns, socket) do
    dfd = Valentine.Composer.DataFlowDiagram.get(assigns.workspace_id)

    element = resolve_element(dfd, assigns.element_id)

    linked_threats =
      if element do
        Valentine.Composer.list_threats_by_ids(element["data"]["linked_threats"])
      else
        []
      end

    threats = Composer.get_workspace!(assigns.workspace_id, [:threats]).threats

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:element, element)
     |> assign(:linked_threats, linked_threats)
     |> assign(:threats, threats)}
  end

  defp resolve_element(dfd, element_id) do
    cond do
      Map.has_key?(dfd.nodes, element_id) -> dfd.nodes[element_id]
      Map.has_key?(dfd.edges, element_id) -> dfd.edges[element_id]
      true -> nil
    end
  end
end
