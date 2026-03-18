defmodule ValentineWeb.WorkspaceLive.Components.MitigationComponent do
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
    ~H"""
    <div style="width:100%">
      <div class="clearfix mb-3">
        <div class="float-left">
          <h3>Mitigation {@mitigation.numeric_id}</h3>
        </div>
        <.live_component
          module={ValentineWeb.WorkspaceLive.Components.LabelSelectComponent}
          id={"mitigations-status-#{@mitigation.id}"}
          parent_id={@myself}
          icon="stack-16"
          default_value="Not set"
          value={@mitigation.status}
          field="status"
          items={[
            {:identified, nil},
            {:in_progress, "State--merged"},
            {:resolved, "State--open"},
            {:will_not_action, "State--closed"}
          ]}
        />
        <div class="float-right">
          <.button
            is_icon_button
            aria-label="Linked assumptions"
            phx-click={
              JS.patch(
                ~p"/workspaces/#{@mitigation.workspace_id}/mitigations/#{@mitigation.id}/assumptions"
              )
            }
            id={"linked-mitigation-assumptions-#{@mitigation.id}"}
          >
            <.octicon name="discussion-closed-16" /> {gettext("Assumptions")}
            <.counter>{assoc_length(@mitigation.assumptions)}</.counter>
          </.button>
          <.button
            is_icon_button
            aria-label="Linked threats"
            phx-click={
              JS.patch(
                ~p"/workspaces/#{@mitigation.workspace_id}/mitigations/#{@mitigation.id}/threats"
              )
            }
            id={"linked-mitigation-threats-#{@mitigation.id}"}
          >
            <.octicon name="squirrel-16" /> {gettext("Threats")}
            <.counter>{assoc_length(@mitigation.threats)}</.counter>
          </.button>
          <.button
            is_icon_button
            aria-label="Categorize"
            phx-click={
              JS.patch(
                ~p"/workspaces/#{@mitigation.workspace_id}/mitigations/#{@mitigation.id}/categorize"
              )
            }
            id={"categorize-mitigation-#{@mitigation.id}"}
          >
            <.octicon name="dependabot-16" />
          </.button>
          <.button
            is_icon_button
            aria-label="Edit"
            phx-click={
              JS.patch(~p"/workspaces/#{@mitigation.workspace_id}/mitigations/#{@mitigation.id}/edit")
            }
            id={"edit-mitigation-#{@mitigation.id}"}
          >
            <.octicon name="pencil-16" />
          </.button>
          <.button
            is_icon_button
            is_danger
            aria-label="Delete"
            phx-click={JS.push("delete", value: %{id: @mitigation.id})}
            data-confirm={gettext("Are you sure?")}
            id={"delete-mitigation-#{@mitigation.id}"}
          >
            <.octicon name="trash-16" />
          </.button>
        </div>
      </div>
      <.styled_html>
        <p>
          {@mitigation.content}
        </p>
      </.styled_html>
      <details class="mt-4" {if @summary_state, do: %{open: true}, else: %{}}>
        <summary phx-click="toggle_summary_state" phx-target={@myself}>{gettext("Comments")}</summary>
        <.live_component
          module={ValentineWeb.WorkspaceLive.Components.TabNavComponent}
          id={"tabs-component-mitigation-#{@mitigation.id}"}
          tabs={[
            %{label: gettext("Write"), id: "tab1"},
            %{label: gettext("Preview"), id: "tab2"}
          ]}
        >
          <:tab_content :let={tab}>
            <form
              phx-value-id={@mitigation.id}
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
                    input_id={"comments-for-#{@mitigation.id}"}
                    is_full_width
                    rows="7"
                    value={@mitigation.comments}
                    caption={gettext("Markdown is supported")}
                  />
                <% "tab2" -> %>
                  <ValentineWeb.WorkspaceLive.Components.MarkdownComponent.render text={
                    @mitigation.comments
                  } />
                  <input type="hidden" name="comments" value={@mitigation.comments} />
              <% end %>
              <.button is_primary class="mt-2" type="submit">{gettext("Save")}</.button>
            </form>
          </:tab_content>
        </.live_component>
      </details>
      <hr />
      <div class="clearfix">
        <div class="float-left col-2 mr-2 mt-1">
          <.text_input
            id={"#{@mitigation.id}-tag-field"}
            name={"#{@mitigation.id}-tag"}
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

        <%= for tag <- @mitigation.tags || [] do %>
          <.button_group class="mt-1 float-left mr-2">
            <.button phx-click="view_control_modal" phx-value-nist_id={tag}>
              <span>{tag}</span>
            </.button>
            <.button is_icon_button phx-click="remove_tag" phx-value-tag={tag} phx-target={@myself}>
              <.octicon name="x-16" />
            </.button>
          </.button_group>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{selected_label_dropdown: {_id, field, value}}, socket) do
    {:ok, mitigation} =
      Composer.update_mitigation(
        socket.assigns.mitigation,
        %{}
        |> Map.put(field, value)
      )

    {:ok,
     socket
     |> assign(:mitigation, mitigation)}
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
    current_tags = socket.assigns.mitigation.tags || []

    if tag not in current_tags do
      updated_tags = current_tags ++ [tag]

      case Composer.update_mitigation(socket.assigns.mitigation, %{tags: updated_tags}) do
        {:ok, mitigation} ->
          broadcast_mitigation_change(mitigation)

          {:noreply,
           socket
           |> assign(:tag, "")
           |> assign(:mitigation, mitigation)}

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
    updated_tags = List.delete(socket.assigns.mitigation.tags, tag)

    case Composer.update_mitigation(socket.assigns.mitigation, %{tags: updated_tags}) do
      {:ok, mitigation} ->
        broadcast_mitigation_change(mitigation)
        {:noreply, assign(socket, :mitigation, mitigation)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_comments", %{"comments" => comments}, socket) do
    # Forces a changeset change
    case Composer.update_mitigation(Map.put(socket.assigns.mitigation, :comments, nil), %{
           :comments => comments
         }) do
      {:ok, mitigation} ->
        broadcast_mitigation_change(mitigation)

        {:noreply,
         socket
         |> assign(:summary_state, nil)
         |> assign(:mitigation, mitigation)}

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
    {:noreply, assign(socket, :mitigation, %{socket.assigns.mitigation | comments: comments})}
  end

  defp assoc_length(l) when is_list(l), do: length(l)
  defp assoc_length(_), do: 0

  defp broadcast_mitigation_change(mitigation) do
    ValentineWeb.Endpoint.broadcast(
      "workspace_" <> mitigation.workspace_id,
      "mitigation_updated",
      %{}
    )
  end
end
