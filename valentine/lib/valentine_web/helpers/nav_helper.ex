defmodule ValentineWeb.Helpers.NavHelper do
  use ValentineWeb, :live_view
  alias ValentineWeb.Presence

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_module, :handle_params, &set_active_module/3)}
  end

  defp set_active_module(params, _url, socket) do
    workspace_id =
      case Map.get(params, "workspace_id") do
        nil -> Map.get(params, "id", nil)
        id -> id
      end

    active_module =
      socket.view
      |> to_string()
      |> String.split(".")
      |> Enum.slice(3..-1//1)
      |> case do
        ["ThreatModel", nested_name | _] when nested_name in ["ReviewIndex", "ReviewShow"] ->
          nested_name

        [name | _] ->
          name
      end

    Presence.track(self(), "valentine:presence", socket.assigns.current_user, %{
      action: socket.assigns.live_action,
      module: active_module,
      workspace_id: workspace_id
    })

    {:cont,
     socket
     |> assign(active_module: active_module)
     |> assign(active_action: socket.assigns.live_action)
     |> assign(:workspace_id, workspace_id)}
  end
end
