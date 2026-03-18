defmodule ValentineWeb.WorkspaceLive.Components.ThreatComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:summary_state, nil)}
  end

  @impl true
  def render(assigns) do
    if assigns.threat == nil do
      ""
    else
      ~H"""
      <div style="width:100%">
        <div class="clearfix mb-3">
          <div class="float-left">
            <h3>Threat {@threat.numeric_id}</h3>
          </div>
          <.live_component
            module={ValentineWeb.WorkspaceLive.Components.LabelSelectComponent}
            id={"threat-priority-#{@threat.id}"}
            parent_id={@myself}
            icon="list-ordered-16"
            default_value="Not set"
            value={@threat.priority}
            field="priority"
            items={[
              {:low, "State--open"},
              {:medium, "color-bg-accent-emphasis color-fg-on-emphasis"},
              {:high, "State--closed"}
            ]}
          />
          <.live_component
            module={ValentineWeb.WorkspaceLive.Components.LabelSelectComponent}
            id={"threat-status-#{@threat.id}"}
            parent_id={@myself}
            icon="stack-16"
            default_value="Not set"
            value={@threat.status}
            field="status"
            items={[
              {:identified, "State--closed"},
              {:resolved, "State--open"},
              {:not_useful, nil}
            ]}
          />
          <div class="float-right">
            <.button
              is_icon_button
              aria-label="Linked assumptions"
              phx-click={
                JS.patch(~p"/workspaces/#{@threat.workspace_id}/threats/#{@threat.id}/assumptions")
              }
              id={"linked-threat-assumptions-#{@threat.id}"}
            >
              <.octicon name="discussion-closed-16" /> {gettext("Assumptions")}
              <.counter>{assoc_length(@threat.assumptions)}</.counter>
            </.button>
            <.button
              is_icon_button
              aria-label="Linked mitigations"
              phx-click={
                JS.patch(~p"/workspaces/#{@threat.workspace_id}/threats/#{@threat.id}/mitigations")
              }
              id={"linked-threat-mitigations-#{@threat.id}"}
            >
              <.octicon name="check-circle-16" /> {gettext("Mitigations")}
              <.counter>{assoc_length(@threat.mitigations)}</.counter>
            </.button>
            <.button
              is_icon_button
              aria-label="Edit"
              navigate={~p"/workspaces/#{@threat.workspace_id}/threats/#{@threat.id}"}
            >
              <.octicon name="pencil-16" />
            </.button>
            <.button
              is_icon_button
              is_danger
              aria-label="Delete"
              phx-click={JS.push("delete", value: %{id: @threat.id})}
              data-confirm={gettext("Are you sure?")}
            >
              <.octicon name="trash-16" />
            </.button>
          </div>
        </div>
        <.styled_html>
          {Valentine.Composer.Threat.show_statement(@threat)}
        </.styled_html>
        <details class="mt-4" {if @summary_state, do: %{open: true}, else: %{}}>
          <summary phx-click="toggle_summary_state" phx-target={@myself}>{gettext("Comments")}</summary>
          <.live_component
            module={ValentineWeb.WorkspaceLive.Components.TabNavComponent}
            id={"tabs-component-threat-#{@threat.id}"}
            tabs={[
              %{label: gettext("Write"), id: "tab1"},
              %{label: gettext("Preview"), id: "tab2"}
            ]}
          >
            <:tab_content :let={tab}>
              <form
                phx-value-id={@threat.id}
                phx-submit="save_comments"
                phx-change="update_comments"
                phx-target={@myself}
              >
                <%= case tab do %>
                  <% "tab1" -> %>
                    <.textarea
                      name="comments"
                      class="mt-2"
                      placeholder={gettext("Add a comment...")}
                      input_id={"comments-for-#{@threat.id}"}
                      is_full_width
                      rows="7"
                      value={@threat.comments}
                      caption={gettext("Markdown is supported")}
                    />
                  <% "tab2" -> %>
                    <ValentineWeb.WorkspaceLive.Components.MarkdownComponent.render text={
                      @threat.comments
                    } />
                    <input type="hidden" name="comments" value={@threat.comments} />
                <% end %>
                <.button is_primary class="mt-2" type="submit">{gettext("Save")}</.button>
              </form>
            </:tab_content>
          </.live_component>
        </details>
        <hr />
        <div class="clearfix mt-4">
          <div class="float-left col-2 mr-2 mt-1">
            <.text_input
              id={"#{@threat.id}-tag-field"}
              name={"#{@threat.id}-tag"}
              placeholder={gettext("Add a tag")}
              phx-keyup="set_tag"
              phx-target={@myself}
              value={@tag}
            >
              <:group_button>
                <.button phx-click="add_tag" phx-target={@myself}>{gettext("Add")}</.button>
              </:group_button>
            </.text_input>
          </div>

          <%= for tag <- @threat.tags || [] do %>
            <.button_group class="mt-1 float-left mr-2">
              <.button phx-click="view_control_modal" phx-value-nist_id={tag}>
                <span>{tag}</span>
              </.button>
              <.button is_icon_button phx-click="remove_tag" phx-value-tag={tag} phx-target={@myself}>
                <.octicon name="x-16" />
              </.button>
            </.button_group>
          <% end %>
          <div class="text-bold f4 float-right" style="color:#cecece">
            {Valentine.Composer.Threat.stride_banner(@threat)}
          </div>
        </div>
      </div>
      """
    end
  end

  @impl true
  def update(%{selected_label_dropdown: {_id, field, value}}, socket) do
    {:ok, threat} =
      Composer.update_threat(
        socket.assigns.threat,
        %{}
        |> Map.put(field, value)
      )

    {:ok,
     socket
     |> assign(:threat, threat)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tag, "")}
  end

  @impl true
  def handle_event("add_tag", _params, %{assigns: %{tag: tag}} = socket)
      when byte_size(tag) > 0 do
    current_tags = socket.assigns.threat.tags || []

    if tag not in current_tags do
      updated_tags = current_tags ++ [tag]

      case Composer.update_threat(socket.assigns.threat, %{tags: updated_tags}) do
        {:ok, threat} ->
          broadcast_threat_change(threat)

          {:noreply,
           socket
           |> assign(:tag, "")
           |> assign(:threat, threat)}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_tag", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    updated_tags = List.delete(socket.assigns.threat.tags, tag)

    case Composer.update_threat(socket.assigns.threat, %{tags: updated_tags}) do
      {:ok, threat} ->
        broadcast_threat_change(threat)
        {:noreply, assign(socket, :threat, threat)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_comments", %{"comments" => comments}, socket) do
    # Forces a changeset change
    case Composer.update_threat(Map.put(socket.assigns.threat, :comments, nil), %{
           :comments => comments
         }) do
      {:ok, threat} ->
        broadcast_threat_change(threat)

        {:noreply,
         socket
         |> assign(:summary_state, nil)
         |> assign(:threat, threat)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("set_tag", %{"value" => value} = _params, socket) do
    {:noreply, assign(socket, :tag, value)}
  end

  @impl true
  def handle_event("toggle_summary_state", _, socket) do
    {:noreply, assign(socket, :summary_state, !socket.assigns.summary_state)}
  end

  def handle_event("update_comments", %{"comments" => comments}, socket) do
    {:noreply, assign(socket, :threat, %{socket.assigns.threat | comments: comments})}
  end

  defp assoc_length(l) when is_list(l), do: length(l)
  defp assoc_length(_), do: 0

  defp broadcast_threat_change(threat) do
    ValentineWeb.Endpoint.broadcast(
      "workspace_" <> threat.workspace_id,
      "threat_updated",
      %{}
    )
  end
end
