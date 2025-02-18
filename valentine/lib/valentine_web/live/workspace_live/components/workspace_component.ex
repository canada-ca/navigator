defmodule ValentineWeb.WorkspaceLive.Components.WorkspaceComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  @impl true
  def render(assigns) do
    ~H"""
    <div style="width:100%">
      <div class="clearfix">
        <div class="float-left">
          <.link navigate={~p"/workspaces/#{@workspace}"}>{@workspace.name}</.link>
        </div>
        <div :if={@current_user == @workspace.owner} class="float-right">
          <.button
            is_icon_button
            aria-label="Edit"
            phx-click={JS.patch(~p"/workspaces/#{@workspace.id}/edit")}
            id={"edit-workspace-#{@workspace.id}"}
          >
            <.octicon name="pencil-16" />
          </.button>
          <.button
            is_icon_button
            is_danger
            aria-label="Delete"
            phx-click={JS.push("delete", value: %{workspace_id: @workspace.id})}
            data-confirm={gettext("Are you sure?")}
            id={"delete-workspace-#{@workspace.id}"}
          >
            <.octicon name="trash-16" />
          </.button>
        </div>
        <div class="float-right mt-1">
          <ValentineWeb.WorkspaceLive.Components.PresenceIndicatorComponent.render
            current_user={@current_user}
            presence={@presence}
            active_module={nil}
            workspace_id={@workspace.id}
          />
        </div>
      </div>
    </div>
    """
  end
end
