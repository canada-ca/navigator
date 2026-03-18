defmodule ValentineWeb.WorkspaceLive.Brainstorm.Components.ThreatBuilderComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Threat

  @required_types [:threat, :attack_vector, :impact, :asset]
  @eligible_statuses [:candidate, :used]

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:selected_cards, %{})
     |> assign(:preview_threat, nil)
     |> assign(:missing_required_types, @required_types)
     |> assign(:validation_errors, [])
     |> assign(:saving, false)
     |> assign(:available_cards, %{})}
  end

  @impl true
  def update(assigns, socket) do
    available_cards = load_available_cards(assigns.workspace_id, assigns[:cluster_key])
    selected_cards = sanitize_selected_cards(socket.assigns.selected_cards, available_cards)
    missing_required_types = missing_required_types(available_cards)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_cards, selected_cards)
     |> assign(:available_cards, available_cards)
     |> assign(:missing_required_types, missing_required_types)
     |> validate_selection()
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
          <div class="threat-builder-modal">
            <div class="threat-builder-intro">
              <div>
                <h4 class="threat-builder-title">{gettext("Build from brainstorm cards")}</h4>
                <p class="threat-builder-copy">
                  {gettext(
                    "Select one eligible card from each required category. Only Candidate and Used cards appear here."
                  )}
                </p>
              </div>
              <div class="threat-builder-status-key" aria-label={gettext("Eligible card statuses")}>
                <span class="Label Label--success">{gettext("Candidate")}</span>
                <span class="Label Label--secondary">{gettext("Used")}</span>
              </div>
            </div>

            <%= if @missing_required_types != [] do %>
              <div class="flash flash-warn threat-builder-warning" role="status">
                <.octicon name="alert-16" />
                <div>
                  <div class="text-bold">{gettext("More brainstorm cards are needed")}</div>
                  <div class="text-small">
                    {gettext(
                      "Add or promote these categories to Candidate or Used before building a threat: %{types}",
                      types: humanize_type_list(@missing_required_types)
                    )}
                  </div>
                </div>
              </div>
            <% end %>

            <div class="threat-builder-layout">
              <section class="threat-builder-panel threat-builder-selection">
                <div class="threat-builder-panel-header">
                  <h5>{gettext("Required components")}</h5>
                  <p>
                    {gettext(
                      "Threat, attack vector, threat impact, and at least one asset are required."
                    )}
                  </p>
                </div>

                <form
                  phx-change="select_card"
                  phx-target={@myself}
                  class="threat-builder-selection-form"
                >
                  <div class="threat-builder-section-list">
                    <%= for {type, cards} <- get_required_types(@available_cards) do %>
                      <.card_selection_section
                        type={type}
                        cards={cards}
                        selected_value={Map.get(@selected_cards, type)}
                      />
                    <% end %>
                  </div>

                  <%= if has_optional_types?(@available_cards) do %>
                    <div class="threat-builder-optional-block">
                      <div class="threat-builder-panel-header">
                        <h5>{gettext("Optional context")}</h5>
                        <p>{gettext("Use these cards to enrich the generated statement.")}</p>
                      </div>

                      <div class="threat-builder-section-list">
                        <%= for {type, cards} <- get_optional_types(@available_cards) do %>
                          <.card_selection_section
                            type={type}
                            cards={cards}
                            selected_value={Map.get(@selected_cards, type)}
                            optional={true}
                          />
                        <% end %>
                      </div>
                    </div>
                  <% end %>

                  <%= if @validation_errors != [] do %>
                    <div class="flash flash-error threat-builder-errors">
                      <.octicon name="stop-16" />
                      <ul class="mb-0 pl-3">
                        <%= for error <- @validation_errors do %>
                          <li>{error}</li>
                        <% end %>
                      </ul>
                    </div>
                  <% end %>
                </form>
              </section>

              <aside class="threat-builder-panel threat-builder-preview">
                <div class="threat-builder-panel-header">
                  <h5>{gettext("Preview")}</h5>
                  <p>{gettext("Review the generated statement before saving.")}</p>
                </div>

                <%= if @preview_threat do %>
                  <div class="threat-builder-preview-card Box p-3">
                    <div class="threat-statement">
                      {Threat.show_statement(@preview_threat)}
                    </div>
                    <%= if has_stride_categories?(@preview_threat) do %>
                      <div class="threat-stride mt-3">
                        {Phoenix.HTML.raw(Threat.stride_banner(@preview_threat))}
                      </div>
                    <% end %>
                  </div>
                <% else %>
                  <div class="blankslate threat-builder-preview-empty">
                    <.octicon name="info-16" class="blankslate-icon" />
                    <h3 class="blankslate-heading">{gettext("Select required components")}</h3>
                    <p>
                      {gettext(
                        "Choose a threat, attack vector, impact, and asset card to generate the final statement preview."
                      )}
                    </p>
                  </div>
                <% end %>
              </aside>
            </div>

            <%= if @validation_errors != [] do %>
              <div class="sr-only" aria-live="polite">
                {Enum.join(@validation_errors, ". ")}
              </div>
            <% end %>
          </div>
        </:body>
        <:footer>
          <div class="d-flex justify-content-between align-items-center threat-builder-footer">
            <div class="text-small color-fg-muted">
              <%= if @preview_threat do %>
                {gettext("1 threat will be created")}
              <% else %>
                {gettext("Complete the required selections to continue")}
              <% end %>
            </div>
            <div class="threat-builder-footer-actions">
              <.button
                phx-click="close_builder"
                phx-target={@myself}
                class="threat-builder-footer-button"
              >
                {gettext("Cancel")}
              </.button>
              <.button
                is_primary
                phx-click="save_threats"
                phx-target={@myself}
                class="threat-builder-footer-button"
                is_disabled={!can_save?(@preview_threat, @validation_errors) || @saving}
              >
                <%= if @saving do %>
                  {gettext("Saving...")}
                <% else %>
                  {gettext("Save Threat")}
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
    assigns = assign_new(assigns, :selected_value, fn -> nil end)

    ~H"""
    <div class="FormControl threat-builder-card-section">
      <div class="FormControl-label d-flex align-items-center gap-2 threat-builder-field-label">
        <.octicon name={type_icon(@type)} />
        <span class="text-bold">{type_display_name(@type)}</span>
      </div>
      <div class="FormControl-input-wrap">
        <%= if Enum.empty?(@cards) do %>
          <div class="text-small color-fg-muted threat-builder-empty-option">
            {gettext("No eligible %{type} cards available",
              type: type_display_name(@type) |> String.downcase()
            )}
            <div>
              {gettext("Move brainstorm cards in this category to Candidate or Used on the board.")}
            </div>
          </div>
        <% else %>
          <%= if @type == :asset do %>
            <div
              class="threat-builder-checkbox-list"
              role="group"
              aria-label={gettext("Select assets")}
            >
              <%= for card <- @cards do %>
                <label class="threat-builder-checkbox-option">
                  <input
                    type="checkbox"
                    name="asset[]"
                    value={card.id}
                    checked={asset_selected?(@selected_value, card.id)}
                  />
                  <span>{card_option_label(card)}</span>
                </label>
              <% end %>
            </div>
            <div class="FormControl-caption threat-builder-field-caption">
              {gettext("Select one or more impacted assets.")}
            </div>
          <% else %>
            <select class="FormControl-input threat-builder-select" name={Atom.to_string(@type)}>
              <option value="">
                {gettext("Select %{type}...", type: type_display_name(@type) |> String.downcase())}
              </option>
              <%= for card <- @cards do %>
                <option value={card.id} selected={@selected_value == card.id}>
                  {card_option_label(card)}
                </option>
              <% end %>
            </select>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_card", params, socket) do
    {type_atom, selected_value} = extract_selected_card(params)

    selected_cards =
      if empty_selection?(selected_value) do
        Map.delete(socket.assigns.selected_cards, type_atom)
      else
        Map.put(socket.assigns.selected_cards, type_atom, selected_value)
      end

    {:noreply,
     socket
     |> assign(:selected_cards, selected_cards)
     |> validate_selection()
     |> update_preview()}
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
    |> Enum.filter(&eligible_card?/1)
    |> Enum.group_by(& &1.type)
  end

  defp get_required_types(available_cards) do
    Enum.map(@required_types, &{&1, Map.get(available_cards, &1, [])})
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
    if previewable_selection?(selected_cards, available_cards) do
      card_data = get_selected_card_data(selected_cards, available_cards)
      threat_attrs = build_threat_attributes(card_data)

      struct(Threat, threat_attrs)
    else
      nil
    end
  end

  defp get_selected_card_data(selected_cards, available_cards) do
    Enum.reduce(selected_cards, %{}, fn {type, selected_value}, acc ->
      cards = find_cards_by_selection(available_cards, selected_value)

      case cards do
        [] -> acc
        [card] -> Map.put(acc, type, card)
        many_cards -> Map.put(acc, type, many_cards)
      end
    end)
  end

  defp find_card_by_id(available_cards, card_id) do
    available_cards
    |> Map.values()
    |> List.flatten()
    |> Enum.find(&(&1.id == card_id))
  end

  defp find_cards_by_selection(_available_cards, nil), do: []

  defp find_cards_by_selection(available_cards, selected_value) when is_list(selected_value) do
    selected_value
    |> Enum.map(&find_card_by_id(available_cards, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp find_cards_by_selection(available_cards, selected_value) do
    case find_card_by_id(available_cards, selected_value) do
      nil -> []
      card -> [card]
    end
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
      cards when is_list(cards) -> Enum.map(cards, & &1.normalized_text)
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
    missing_types = missing_required_types(socket.assigns.available_cards)

    availability_errors =
      Enum.map(missing_types, fn type ->
        gettext("No eligible %{type} cards are available", type: type_display_name(type))
      end)

    selection_errors =
      @required_types
      |> Enum.reject(
        &(&1 in missing_types || valid_selection?(Map.get(socket.assigns.selected_cards, &1)))
      )
      |> Enum.map(fn type ->
        gettext("Select a %{type} card", type: type_display_name(type))
      end)

    assign(socket, :validation_errors, availability_errors ++ selection_errors)
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
    selected_card_ids = selected_card_ids(socket.assigns.selected_cards)

    threat_attrs =
      socket.assigns.preview_threat
      |> Map.from_struct()
      |> Map.put(:workspace_id, socket.assigns.workspace_id)

    case Composer.create_threat(threat_attrs) do
      {:ok, threat} ->
        update_card_usage(selected_card_ids, threat.numeric_id)
        {:ok, [threat]}

      {:error, changeset} ->
        {:error, ["Failed to save threat: #{format_changeset_errors(changeset)}"]}
    end
  end

  defp update_card_usage(card_ids, threat_numeric_id) do
    Enum.each(card_ids, fn card_id ->
      case Composer.get_brainstorm_item(card_id) do
        nil ->
          :skip

        item ->
          Composer.mark_used_in_threat(item, threat_numeric_id)
      end
    end)
  end

  defp can_save?(nil, _errors), do: false
  defp can_save?(_threat, errors) when length(errors) > 0, do: false
  defp can_save?(_threat, _errors), do: true

  defp eligible_card?(item), do: item.status in @eligible_statuses

  defp missing_required_types(available_cards) do
    Enum.filter(@required_types, fn type ->
      Map.get(available_cards, type, []) == []
    end)
  end

  defp previewable_selection?(selected_cards, available_cards) do
    missing_required_types(available_cards) == [] and
      Enum.all?(@required_types, &valid_selection?(Map.get(selected_cards, &1)))
  end

  defp sanitize_selected_cards(selected_cards, available_cards) do
    Enum.reduce(selected_cards, %{}, fn {type, selected_value}, acc ->
      sanitized_value = sanitize_selected_value(available_cards, selected_value)

      if empty_selection?(sanitized_value) do
        acc
      else
        Map.put(acc, type, sanitized_value)
      end
    end)
  end

  defp extract_selected_card(params) do
    type_key =
      case Map.get(params, "_target") do
        [target_key | _rest] when is_binary(target_key) ->
          if existing_type_key?(target_key) do
            target_key
          end

        _ ->
          nil
      end ||
        params
        |> Map.drop(["_target"])
        |> Map.keys()
        |> Enum.find(&(existing_type_key?(&1) and is_binary(params[&1])))

    type_atom = String.to_existing_atom(type_key)
    {type_atom, normalize_selected_value(type_atom, Map.get(params, type_key, ""))}
  end

  defp normalize_selected_value(:asset, value) when is_list(value) do
    value
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp normalize_selected_value(:asset, value) when is_binary(value) do
    normalize_selected_value(:asset, [value])
  end

  defp normalize_selected_value(_type, value), do: value

  defp sanitize_selected_value(available_cards, selected_value) when is_list(selected_value) do
    selected_value
    |> Enum.filter(&(find_card_by_id(available_cards, &1) != nil))
    |> Enum.uniq()
  end

  defp sanitize_selected_value(available_cards, selected_value) do
    if find_card_by_id(available_cards, selected_value), do: selected_value, else: nil
  end

  defp selected_card_ids(selected_cards) do
    selected_cards
    |> Map.values()
    |> Enum.flat_map(fn
      values when is_list(values) -> values
      value -> [value]
    end)
    |> Enum.uniq()
  end

  defp valid_selection?(value) when is_list(value), do: value != []
  defp valid_selection?(value), do: value not in [nil, ""]

  defp empty_selection?(value), do: not valid_selection?(value)

  defp asset_selected?(selected_value, card_id) when is_list(selected_value),
    do: card_id in selected_value

  defp asset_selected?(_, _), do: false

  defp existing_type_key?(key) do
    try do
      String.to_existing_atom(key) in (@required_types ++
                                         [:requirement, :risk, :assumption, :mitigation])
    rescue
      ArgumentError -> false
    end
  end

  defp card_option_label(card) do
    suffix = if card.status == :used, do: gettext(" (already used)"), else: ""
    card.normalized_text <> suffix
  end

  defp has_stride_categories?(%Threat{stride: stride}) when is_list(stride), do: stride != []
  defp has_stride_categories?(_), do: false

  defp humanize_type_list(types) do
    types
    |> Enum.map(&type_display_name/1)
    |> Enum.join(", ")
  end

  defp type_display_name(type) do
    case type do
      :impact ->
        "Threat Impact"

      _ ->
        type
        |> Atom.to_string()
        |> String.replace("_", " ")
        |> String.split()
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")
    end
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
