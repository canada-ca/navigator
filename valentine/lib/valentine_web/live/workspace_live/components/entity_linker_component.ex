defmodule ValentineWeb.WorkspaceLive.Components.EntityLinkerComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog id="linker-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@patch)}>
        <:header_title>
          {gettext("Link %{source_entity_type} to %{target_entity_type}",
            source_entity_type: Atom.to_string(@source_entity_type),
            target_entity_type: Atom.to_string(@target_entity_type)
          )}
        </:header_title>
        <:body>
          <.live_component
            module={ValentineWeb.WorkspaceLive.Components.DropdownSelectComponent}
            id="link-dropdown"
            name={Atom.to_string(@target_entity_type)}
            target={@myself}
            items={
              (@linkable_entities -- @linked_entities)
              |> Enum.map(fn e -> %{id: e.id, name: entity_content(e)} end)
            }
          />
          <div class="mt-2">
            <%= for entity <- @linked_entities || [] do %>
              <.button
                phx-click="remove_entity"
                phx-target={@myself}
                phx-value-id={entity.id}
                class="tag-button mt-2"
              >
                <span>{entity_content(entity)}</span>
                <.octicon name="x-16" />
              </.button>
            <% end %>
          </div>
        </:body>
        <:footer>
          <.button is_primary phx-click="save" phx-target={@myself}>
            {gettext("Save")}
          </.button>
          <.button phx-click={cancel_dialog("linker-modal")}>{gettext("Cancel")}</.button>
        </:footer>
      </.dialog>
    </div>
    """
  end

  @impl true
  def handle_event("remove_entity", %{"id" => id}, socket) do
    entity = Enum.find(socket.assigns.linked_entities, fn t -> t.id == id end)

    {:noreply,
     socket
     |> assign(:linked_entities, socket.assigns.linked_entities -- [entity])
     |> assign(:linkable_entities, [entity | socket.assigns.linkable_entities])}
  end

  @impl true
  def handle_event("save", _params, socket) do
    %{
      entity: entity,
      linked_entities: linked_entities,
      source_entity_type: source_entity_type,
      target_entity_type: target_entity_type
    } =
      socket.assigns

    current = get_in(entity, [Access.key!(target_entity_type)])

    to_add = linked_entities -- current
    to_remove = current -- linked_entities

    {adder, remover} =
      case {source_entity_type, target_entity_type} do
        {:assumption, :mitigations} ->
          {&Valentine.Composer.add_mitigation_to_assumption/2,
           &Valentine.Composer.remove_mitigation_from_assumption/2}

        {:assumption, :threats} ->
          {&Valentine.Composer.add_threat_to_assumption/2,
           &Valentine.Composer.remove_threat_from_assumption/2}

        {:mitigation, :assumptions} ->
          {&Valentine.Composer.add_assumption_to_mitigation/2,
           &Valentine.Composer.remove_assumption_from_mitigation/2}

        {:mitigation, :threats} ->
          {&Valentine.Composer.add_threat_to_mitigation/2,
           &Valentine.Composer.remove_threat_from_mitigation/2}

        {:threat, :assumptions} ->
          {&Valentine.Composer.add_assumption_to_threat/2,
           &Valentine.Composer.remove_assumption_from_threat/2}

        {:threat, :mitigations} ->
          {&Valentine.Composer.add_mitigation_to_threat/2,
           &Valentine.Composer.remove_mitigation_from_threat/2}

        {:evidence, :assumptions} ->
          {&Valentine.Composer.add_assumption_to_evidence/2,
           &Valentine.Composer.remove_assumption_from_evidence/2}

        {:evidence, :threats} ->
          {&Valentine.Composer.add_threat_to_evidence/2,
           &Valentine.Composer.remove_threat_from_evidence/2}

        {:evidence, :mitigations} ->
          {&Valentine.Composer.add_mitigation_to_evidence/2,
           &Valentine.Composer.remove_mitigation_from_evidence/2}

        {_, _} ->
          {nil, nil}
      end

    if adder && remover do
      to_add
      |> Enum.each(fn e -> apply(adder, [entity, e]) end)

      to_remove
      |> Enum.each(fn e -> apply(remover, [entity, e]) end)

      send(self(), {__MODULE__, {:saved, entity}})
    end

    {:noreply,
     socket
     |> put_flash(
       :info,
       gettext("Linked %{source_entity_type} updated",
         source_entity_type: Atom.to_string(source_entity_type)
       )
     )
     |> push_patch(to: socket.assigns.patch)}
  end

  @impl true
  def update(%{selected_item: %{id: id}}, socket) do
    entity = Enum.find(socket.assigns.linkable_entities, fn t -> t.id == id end)

    {:ok,
     socket
     |> assign(:linked_entities, [entity | socket.assigns.linked_entities])
     |> assign(
       :linkable_entities,
       socket.assigns.linkable_entities
       |> Enum.reject(fn t -> t.id == id end)
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  defp entity_content(%Valentine.Composer.Threat{} = threat),
    do: Valentine.Composer.Threat.show_statement(threat)

  defp entity_content(%Valentine.Composer.Evidence{} = evidence), do: evidence.name

  defp entity_content(entity), do: entity.content
end
