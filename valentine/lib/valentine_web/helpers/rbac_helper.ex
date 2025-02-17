defmodule ValentineWeb.Helpers.RbacHelper do
  use ValentineWeb, :live_view

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
