defmodule ValentineWeb.Helpers.RbacHelper do
  import Phoenix.LiveView, only: [attach_hook: 4, connected?: 1, redirect: 2]

  alias Phoenix.Component
  alias Valentine.Composer.Workspace
  alias Valentine.Composer.Workspaces

  def init(default), do: default

  def call(conn, _) do
    case conn.params do
      %{"workspace_id" => workspace_id} ->
        identity = Plug.Conn.get_session(conn, "user_id")

        case Workspaces.authorize(workspace_id, identity, :read) do
          {:error, _reason} ->
            Phoenix.Controller.redirect(conn, to: "/workspaces")
            |> Plug.Conn.halt()

          {:ok, _workspace} ->
            conn
        end

      _ ->
        conn
    end
  end

  def on_mount(:default, %{"workspace_id" => workspace_id}, _session, socket) do
    check_permissions(workspace_id, socket)
  end

  def on_mount(:default, _params, _session, socket), do: {:cont, socket}

  defp check_permissions(workspace_id, socket) do
    case Workspaces.authorize(workspace_id, socket.assigns.current_user, :read) do
      {:error, _reason} ->
        {:halt, redirect(socket, to: "/workspaces")}

      {:ok, workspace} ->
        permission = Workspace.check_workspace_permissions(workspace, socket.assigns.current_user)

        socket =
          socket
          |> Component.assign(:rbac_workspace_id, workspace_id)
          |> assign_permission(permission)
          |> subscribe_to_permission_updates(workspace_id)

        enforce_route_capability(socket, workspace_id)
    end
  end

  defp assign_permission(socket, permission) do
    Component.assign(socket,
      workspace_permission: permission,
      workspace_can_read: Workspace.can_read?(permission),
      workspace_can_write: Workspace.can_write?(permission),
      workspace_can_manage: Workspace.can_manage?(permission)
    )
  end

  defp subscribe_to_permission_updates(socket, workspace_id) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Valentine.PubSub, Workspaces.permission_topic(workspace_id))

      attach_hook(
        socket,
        :workspace_permission_updates,
        :handle_info,
        &handle_permission_update/2
      )
    else
      socket
    end
  end

  defp handle_permission_update(
         {:workspace_permission_updated, workspace_id, _collaborator_identity},
         %{assigns: %{rbac_workspace_id: workspace_id}} = socket
       ) do
    case Workspaces.authorize(workspace_id, socket.assigns.current_user, :read) do
      {:ok, workspace} ->
        permission = Workspace.check_workspace_permissions(workspace, socket.assigns.current_user)
        enforce_route_capability(assign_permission(socket, permission), workspace_id)

      {:error, _reason} ->
        {:halt, redirect(socket, to: "/workspaces")}
    end
  end

  defp handle_permission_update(_message, socket), do: {:cont, socket}

  defp enforce_route_capability(socket, workspace_id) do
    capability = required_capability(socket.view, socket.assigns[:live_action])

    if capability_allowed?(socket, capability) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/workspaces/#{workspace_id}")}
    end
  end

  defp capability_allowed?(socket, :read), do: socket.assigns.workspace_can_read
  defp capability_allowed?(socket, :write), do: socket.assigns.workspace_can_write
  defp capability_allowed?(socket, :manage), do: socket.assigns.workspace_can_manage

  defp required_capability(ValentineWeb.WorkspaceLive.Index, :edit), do: :manage

  defp required_capability(ValentineWeb.WorkspaceLive.ApiKey.Index, _action), do: :manage

  defp required_capability(ValentineWeb.WorkspaceLive.Assumption.Index, action)
       when action in [:new, :edit, :categorize, :mitigations, :threats],
       do: :write

  defp required_capability(ValentineWeb.WorkspaceLive.Mitigation.Index, action)
       when action in [:new, :edit, :assumptions, :categorize, :threats],
       do: :write

  defp required_capability(ValentineWeb.WorkspaceLive.ThreatAgent.Index, action)
       when action in [:new, :edit],
       do: :write

  defp required_capability(ValentineWeb.WorkspaceLive.Evidence.Show, :new), do: :write

  defp required_capability(ValentineWeb.WorkspaceLive.Evidence.Index, action)
       when action in [:assumptions, :threats, :mitigations],
       do: :write

  defp required_capability(ValentineWeb.WorkspaceLive.Threat.Show, action)
       when action in [:new, :new_assumption, :new_mitigation],
       do: :write

  defp required_capability(ValentineWeb.WorkspaceLive.Threat.Index, action)
       when action in [:assumptions, :mitigations],
       do: :write

  defp required_capability(ValentineWeb.WorkspaceLive.ReferencePacks.Index, :import), do: :write
  defp required_capability(_view, _action), do: :read
end
