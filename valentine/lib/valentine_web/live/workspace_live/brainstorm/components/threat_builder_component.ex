defmodule ValentineWeb.WorkspaceLive.Brainstorm.Components.ThreatBuilderComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Threat
  alias Valentine.Composer.BrainstormItem

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:selected_cards, %{})
     |> assign(:preview_threat, nil)
     |> assign(:validation_errors, [])
     |> assign(:saving, false)
     |> assign(:available_cards, %{})
     |> assign(:split_assets, false)}
  end

  @impl true
  def update(assigns, socket) do
    # Load available brainstorm items by type
    available_cards = load_available_cards(assigns.workspace_id, assigns[:cluster_key])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:available_cards, available_cards)
     |> update_preview()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog
        id="threat-builder-modal"
        is_backdrop
        is_show
        is_wide
        on_cancel={JS.push("close_builder", target: @myself)}
      >
        <:header_title>
          {gettext("Statement Builder")}
        </:header_title>
        <:body>
          <div class="d-flex flex-column gap-3">
            <!-- Card Selection Section -->
            <div class="threat-builder-selection">
              <h4>{gettext("Select Components")}</h4>
              <div class="text-small color-fg-muted mb-3">
                {gettext(
                  "Choose one card from each required category to build your threat statement."
                )}
              </div>
              
    <!-- Required Categories -->
              <div class="d-flex flex-column gap-2">
                <%= for {type, cards} <- get_required_types(@available_cards) do %>
                  <.card_selection_section
                    type={type}
                    cards={cards}
                    selected_card_id={Map.get(@selected_cards, type)}
                    target={@myself}
                  />
                <% end %>
              </div>
              
    <!-- Optional Categories -->
              <%= if has_optional_types?(@available_cards) do %>
                <details class="mt-3">
                  <summary class="btn-link">{gettext("Optional Components")}</summary>
                  <div class="mt-2 d-flex flex-column gap-2">
                    <%= for {type, cards} <- get_optional_types(@available_cards) do %>
                      <.card_selection_section
                        type={type}
                        cards={cards}
                        selected_card_id={Map.get(@selected_cards, type)}
                        target={@myself}
                        optional={true}
                      />
                    <% end %>
                  </div>
                </details>
              <% end %>
            </div>
            
    <!-- Preview Section -->
            <div class="threat-builder-preview">
              <h4>{gettext("Preview")}</h4>
              <%= if @preview_threat do %>
                <div class="Box p-3">
                  <div class="threat-statement">
                    {Threat.show_statement(@preview_threat)}
                  </div>
                  <div class="threat-stride mt-2">
                    {Phoenix.HTML.raw(Threat.stride_banner(@preview_threat))}
                  </div>
                </div>
                
    <!-- Split Assets Option -->
                <%= if has_multiple_assets?(@preview_threat) do %>
                  <label class="FormControl-label mt-2">
                    <input
                      type="checkbox"
                      phx-click="toggle_split_assets"
                      phx-target={@myself}
                      checked={@split_assets}
                    />
                    {gettext("Create separate threats for each asset")}
                  </label>
                <% end %>
              <% else %>
                <div class="blankslate">
                  <.octicon name="info-16" class="blankslate-icon" />
                  <h3 class="blankslate-heading">{gettext("Select components to preview")}</h3>
                  <p>
                    {gettext(
                      "Choose cards from the required categories to see your threat statement."
                    )}
                  </p>
                </div>
              <% end %>
            </div>
            
    <!-- Validation Errors -->
            <%= if @validation_errors != [] do %>
              <div class="flash flash-error">
                <.octicon name="stop-16" />
                <ul class="mb-0 pl-3">
                  <%= for error <- @validation_errors do %>
                    <li>{error}</li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        </:body>
        <:footer>
          <div class="d-flex justify-content-between align-items-center">
            <div class="text-small color-fg-muted">
              <%= if @preview_threat do %>
                {ngettext(
                  "1 threat will be created",
                  "%{count} threats will be created",
                  threat_count(@preview_threat, @split_assets),
                  count: threat_count(@preview_threat, @split_assets)
                )}
              <% end %>
            </div>
            <div class="d-flex gap-2">
              <.button phx-click="close_builder" phx-target={@myself}>
                {gettext("Cancel")}
              </.button>
              <.button
                is_primary
                phx-click="save_threats"
                phx-target={@myself}
                is_disabled={!can_save?(@preview_threat, @validation_errors) || @saving}
              >
                <%= if @saving do %>
                  {gettext("Saving...")}
                <% else %>
                  {gettext("Save Threat(s)")}
                <% end %>
              </.button>
            </div>
          </div>
        </:footer>
      </.dialog>
    </div>
    """
  end

  # Card selection section component
  defp card_selection_section(assigns) do
    ~H"""
    <div class="FormControl">
      <div class="FormControl-label d-flex align-items-center gap-2">
        <.octicon name={type_icon(@type)} />
        <span class="text-bold">{type_display_name(@type)}</span>
        <%= unless assigns[:optional] do %>
          <span class="Label Label--danger Label--small">Required</span>
        <% end %>
      </div>
      <div class="FormControl-input-wrap">
        <%= if Enum.empty?(@cards) do %>
          <div class="text-small color-fg-muted">
            {gettext("No %{type} cards available",
              type: type_display_name(@type) |> String.downcase()
            )}
          </div>
        <% else %>
          <select
            class="FormControl-input"
            phx-change="select_card"
            phx-target={@target}
            phx-value-type={@type}
          >
            <option value="">
              {gettext("Select %{type}...", type: type_display_name(@type) |> String.downcase())}
            </option>
            <%= for card <- @cards do %>
              <option
                value={card.id}
                selected={@selected_card_id == card.id}
                class={if card.status == :used, do: "text-muted"}
              >
                {card.normalized_text}
                <%= if card.status == :used do %>
                  {gettext(" (already used)")}
                <% end %>
              </option>
            <% end %>
          </select>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_card", %{"type" => type, "value" => card_id}, socket) do
    type_atom = String.to_existing_atom(type)

    selected_cards =
      if card_id == "" do
        Map.delete(socket.assigns.selected_cards, type_atom)
      else
        Map.put(socket.assigns.selected_cards, type_atom, card_id)
      end

    {:noreply,
     socket
     |> assign(:selected_cards, selected_cards)
     |> update_preview()
     |> validate_selection()}
  end

  @impl true
  def handle_event("toggle_split_assets", _params, socket) do
    {:noreply, assign(socket, :split_assets, !socket.assigns.split_assets)}
  end

  @impl true
  def handle_event("save_threats", _params, socket) do
    socket = assign(socket, :saving, true)

    case validate_and_save_threats(socket) do
      {:ok, threats} ->
        send(self(), {:threats_created, threats})
        {:noreply, assign(socket, :saving, false)}

      {:error, errors} ->
        {:noreply,
         socket
         |> assign(:saving, false)
         |> assign(:validation_errors, errors)}
    end
  end

  @impl true
  def handle_event("close_builder", _params, socket) do
    send(self(), :close_threat_builder)
    {:noreply, socket}
  end

  # Private helper functions

  defp load_available_cards(workspace_id, cluster_key) do
    filters = if cluster_key, do: %{cluster_key: cluster_key}, else: %{}

    workspace_id
    |> Composer.list_brainstorm_items(filters)
    |> Enum.reject(&(&1.status == :archived))
    |> Enum.group_by(& &1.type)
  end

  defp get_required_types(available_cards) do
    # Map from brainstorm item types to threat grammar field names  
    required_types = [:threat, :attack_vector, :impact, :asset]

    available_cards
    |> Map.take(required_types)
    |> Enum.filter(fn {_type, cards} -> !Enum.empty?(cards) end)
  end

  defp get_optional_types(available_cards) do
    optional_types = [:requirement, :risk, :assumption, :mitigation]

    available_cards
    |> Map.take(optional_types)
    |> Enum.filter(fn {_type, cards} -> !Enum.empty?(cards) end)
  end

  defp has_optional_types?(available_cards) do
    get_optional_types(available_cards) != []
  end

  defp update_preview(socket) do
    preview_threat =
      build_preview_threat(socket.assigns.selected_cards, socket.assigns.available_cards)

    assign(socket, :preview_threat, preview_threat)
  end

  defp build_preview_threat(selected_cards, available_cards) do
    if map_size(selected_cards) > 0 do
      # Get the actual card data
      card_data = get_selected_card_data(selected_cards, available_cards)

      # Build threat attributes from selected cards
      threat_attrs = build_threat_attributes(card_data)

      # Create a temporary threat struct for preview
      struct(Threat, threat_attrs)
    else
      nil
    end
  end

  defp get_selected_card_data(selected_cards, available_cards) do
    Enum.reduce(selected_cards, %{}, fn {type, card_id}, acc ->
      case find_card_by_id(available_cards, card_id) do
        nil -> acc
        card -> Map.put(acc, type, card)
      end
    end)
  end

  defp find_card_by_id(available_cards, card_id) do
    available_cards
    |> Map.values()
    |> List.flatten()
    |> Enum.find(&(&1.id == card_id))
  end

  defp build_threat_attributes(card_data) do
    %{
      threat_source: get_card_text(card_data, :threat),
      prerequisites: get_card_text(card_data, :requirement),
      threat_action: get_card_text(card_data, :attack_vector),
      threat_impact: get_card_text(card_data, :impact),
      impacted_goal: get_card_array(card_data, :risk),
      impacted_assets: get_card_array(card_data, :asset),
      stride: infer_stride_from_action(get_card_text(card_data, :attack_vector))
    }
  end

  defp get_card_text(card_data, type) do
    case Map.get(card_data, type) do
      nil -> nil
      card -> card.normalized_text
    end
  end

  defp get_card_array(card_data, type) do
    case Map.get(card_data, type) do
      nil -> []
      card -> [card.normalized_text]
    end
  end

  defp infer_stride_from_action(nil), do: []

  defp infer_stride_from_action(action) do
    # Simple heuristic-based STRIDE inference
    action_lower = String.downcase(action)

    cond do
      String.contains?(action_lower, "spoof") or String.contains?(action_lower, "impersonate") or
          String.contains?(action_lower, "fake") ->
        [:spoofing]

      String.contains?(action_lower, "modif") or String.contains?(action_lower, "alter") or
        String.contains?(action_lower, "tamper") or String.contains?(action_lower, "change") ->
        [:tampering]

      String.contains?(action_lower, "repudiate") or String.contains?(action_lower, "claim") ->
        [:repudiation]

      String.contains?(action_lower, "access") or String.contains?(action_lower, "read") or
        String.contains?(action_lower, "disclose") or String.contains?(action_lower, "leak") or
          String.contains?(action_lower, "expose") ->
        [:information_disclosure]

      String.contains?(action_lower, "deny") or String.contains?(action_lower, "block") or
        String.contains?(action_lower, "prevent") or String.contains?(action_lower, "overload") or
          String.contains?(action_lower, "crash") ->
        [:denial_of_service]

      String.contains?(action_lower, "elevate") or String.contains?(action_lower, "escalate") or
        String.contains?(action_lower, "privilege") or String.contains?(action_lower, "admin") or
          String.contains?(action_lower, "root") ->
        [:elevation_of_privilege]

      true ->
        []
    end
  end

  defp validate_selection(socket) do
    errors = []

    # Check for required fields (using brainstorm item types)
    required_types = [:threat, :attack_vector, :impact, :asset]

    missing_required =
      required_types
      |> Enum.reject(&Map.has_key?(socket.assigns.selected_cards, &1))
      |> Enum.map(&"Missing required #{type_display_name(&1) |> String.downcase()}")

    all_errors = errors ++ missing_required

    assign(socket, :validation_errors, all_errors)
  end

  defp validate_and_save_threats(socket) do
    socket = validate_selection(socket)

    if socket.assigns.validation_errors == [] && socket.assigns.preview_threat do
      save_threats(socket)
    else
      {:error, socket.assigns.validation_errors}
    end
  end

  defp save_threats(socket) do
    preview_threat = socket.assigns.preview_threat

    if socket.assigns.split_assets && length(preview_threat.impacted_assets) > 1 do
      save_split_threats(socket)
    else
      save_single_threat(socket)
    end
  end

  defp save_single_threat(socket) do
    selected_card_ids = Map.values(socket.assigns.selected_cards)

    threat_attrs =
      socket.assigns.preview_threat
      |> Map.from_struct()
      |> Map.put(:workspace_id, socket.assigns.workspace_id)

    case Composer.create_threat(threat_attrs) do
      {:ok, threat} ->
        # Mark cards as used and update provenance
        update_card_usage(selected_card_ids, threat.numeric_id)
        {:ok, [threat]}

      {:error, changeset} ->
        {:error, ["Failed to save threat: #{format_changeset_errors(changeset)}"]}
    end
  end

  defp save_split_threats(socket) do
    preview_threat = socket.assigns.preview_threat
    selected_card_ids = Map.values(socket.assigns.selected_cards)

    threats =
      Enum.map(preview_threat.impacted_assets, fn asset ->
        threat_attrs =
          preview_threat
          |> Map.from_struct()
          |> Map.put(:workspace_id, socket.assigns.workspace_id)
          |> Map.put(:impacted_assets, [asset])

        case Composer.create_threat(threat_attrs) do
          {:ok, threat} ->
            update_card_usage(selected_card_ids, threat.numeric_id)
            threat

          {:error, _changeset} ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if length(threats) > 0 do
      {:ok, threats}
    else
      {:error, ["Failed to save split threats"]}
    end
  end

  defp update_card_usage(card_ids, threat_numeric_id) do
    Enum.each(card_ids, fn card_id ->
      case Composer.get_brainstorm_item(card_id) do
        nil ->
          :skip

        item ->
          case BrainstormItem.mark_used_in_threat(item, threat_numeric_id) do
            {:ok, _item} -> :ok
            changeset -> Composer.update_brainstorm_item(item, changeset.changes)
          end
      end
    end)
  end

  defp has_multiple_assets?(threat) do
    threat && length(threat.impacted_assets || []) > 1
  end

  defp threat_count(threat, split_assets) do
    if split_assets && has_multiple_assets?(threat) do
      length(threat.impacted_assets)
    else
      1
    end
  end

  defp can_save?(nil, _errors), do: false
  defp can_save?(_threat, errors) when length(errors) > 0, do: false
  defp can_save?(_threat, _errors), do: true

  defp type_display_name(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp type_icon(:threat), do: "alert-16"
  defp type_icon(:requirement), do: "key-16"
  defp type_icon(:attack_vector), do: "zap-16"
  defp type_icon(:impact), do: "flame-16"
  defp type_icon(:risk), do: "goal-16"
  defp type_icon(:asset), do: "package-16"
  defp type_icon(:assumption), do: "info-16"
  defp type_icon(:mitigation), do: "shield-16"
  defp type_icon(_), do: "circle-16"

  defp format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
