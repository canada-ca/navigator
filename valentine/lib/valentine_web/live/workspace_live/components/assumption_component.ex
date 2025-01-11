defmodule ValentineWeb.WorkspaceLive.Components.AssumptionComponent do
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
          <h3>Assumption {@assumption.numeric_id}</h3>
        </div>
        <div class="float-right">
          <.button
            is_icon_button
            aria-label="Linked threats"
            phx-click={
              JS.patch(
                ~p"/workspaces/#{@assumption.workspace_id}/assumptions/#{@assumption.id}/threats"
              )
            }
            id={"linked-assumption-threats-#{@assumption.id}"}
          >
            <.octicon name="squirrel-16" />
            <.counter>{assoc_length(@assumption.threats)}</.counter>
          </.button>
          <.button
            is_icon_button
            aria-label="Linked mitigations"
            phx-click={
              JS.patch(
                ~p"/workspaces/#{@assumption.workspace_id}/assumptions/#{@assumption.id}/mitigations"
              )
            }
            id={"linked-assumption-mitigations-#{@assumption.id}"}
          >
            <.octicon name="check-circle-16" />
            <.counter>{assoc_length(@assumption.mitigations)}</.counter>
          </.button>
          <.button
            is_icon_button
            aria-label="Edit"
            phx-click={
              JS.patch(~p"/workspaces/#{@assumption.workspace_id}/assumptions/#{@assumption.id}/edit")
            }
            id={"edit-assumption-#{@assumption.id}"}
          >
            <.octicon name="pencil-16" />
          </.button>
          <.button
            is_icon_button
            is_danger
            aria-label="Delete"
            phx-click={JS.push("delete", value: %{id: @assumption.id})}
            data-confirm={gettext("Are you sure?")}
            id={"delete-assumption-#{@assumption.id}"}
          >
            <.octicon name="trash-16" />
          </.button>
        </div>
      </div>
      <.styled_html>
        <p>
          {@assumption.content}
        </p>
      </.styled_html>
      <details class="mt-4" {if @summary_state, do: %{open: true}, else: %{}}>
        <summary phx-click="toggle_summary_state" phx-target={@myself}>{gettext("Comments")}</summary>
        <.live_component
          module={ValentineWeb.WorkspaceLive.Components.TabNavComponent}
          id={"tabs-component-assumption-#{@assumption.id}"}
          tabs={[
            %{label: gettext("Write"), id: "tab1"},
            %{label: gettext("Preview"), id: "tab2"}
          ]}
        >
          <:tab_content :let={tab}>
            <form
              phx-value-id={@assumption.id}
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
                    input_id={"comments-for-#{@assumption.id}"}
                    is_full_width
                    rows="7"
                    value={@assumption.comments}
                    caption={gettext("Markdown is supported")}
                  />
                <% "tab2" -> %>
                  <ValentineWeb.WorkspaceLive.Components.MarkdownComponent.render text={
                    @assumption.comments
                  } />
                  <input type="hidden" name="comments" value={@assumption.comments} />
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
            id={"#{@assumption.id}-tag-field"}
            name={"#{@assumption.id}-tag"}
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

        <%= for tag <- @assumption.tags || [] do %>
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
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tag, "")}
  end

  @impl true
  def handle_event("add_tag", _params, %{assigns: %{tag: tag}} = socket)
      when byte_size(tag) > 0 do
    current_tags = socket.assigns.assumption.tags || []

    if tag not in current_tags do
      updated_tags = current_tags ++ [tag]

      Composer.update_assumption(socket.assigns.assumption, %{tags: updated_tags})

      {:noreply,
       socket
       |> assign(:tag, "")
       |> assign(:assumption, %{socket.assigns.assumption | tags: updated_tags})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_tag", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    updated_tags = List.delete(socket.assigns.assumption.tags, tag)
    Composer.update_assumption(socket.assigns.assumption, %{tags: updated_tags})
    {:noreply, assign(socket, :assumption, %{socket.assigns.assumption | tags: updated_tags})}
  end

  @impl true
  def handle_event("save_comments", %{"comments" => comments}, socket) do
    # Forces a changeset change
    Composer.update_assumption(Map.put(socket.assigns.assumption, :comments, nil), %{
      :comments => comments
    })

    {:noreply,
     socket
     |> assign(:summary_state, nil)
     |> assign(:assumption, %{socket.assigns.assumption | comments: comments})}
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
    {:noreply, assign(socket, :assumption, %{socket.assigns.assumption | comments: comments})}
  end

  defp assoc_length(l) when is_list(l), do: length(l)
  defp assoc_length(_), do: 0
end
