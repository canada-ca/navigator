defmodule ValentineWeb.Helpers.RbacHelper do
  def init(default), do: default

  def call(conn, _) do
    case conn.params do
      %{"workspace_id" => workspace_id} ->
        identity = Plug.Conn.get_session(conn, "user_id")

        case Valentine.Composer.check_workspace_permissions(workspace_id, identity) do
          nil ->
            Phoenix.Controller.redirect(conn, to: "/workspaces")
            |> Plug.Conn.halt()

          _ ->
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
    case Valentine.Composer.check_workspace_permissions(workspace_id, socket.assigns.current_user) do
      nil ->
        {:halt, Phoenix.LiveView.redirect(socket, to: "/workspaces")}

      permission ->
        {:cont, Phoenix.Component.assign(socket, :workspace_permission, permission)}
    end
  end
end
