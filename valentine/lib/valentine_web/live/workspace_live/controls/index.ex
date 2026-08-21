defmodule ValentineWeb.WorkspaceLive.Controls.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer.Controls

  alias Valentine.Composer.Workspaces
  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)

    {:ok,
     socket
     |> assign(:controls, Controls.list_controls())
     |> assign(:nist_families, Controls.list_control_families())
     |> assign(:workspace, workspace)
     |> assign(:filters, %{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "NIST Controls")
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    if Kernel.map_size(filters) == 0 do
      {:noreply,
       socket
       |> assign(:controls, Controls.list_controls())
       |> assign(:filters, filters)}
    else
      {:noreply,
       socket
       |> assign(:controls, Controls.list_controls_in_families(filters.nist_family))
       |> assign(:filters, filters)}
    end
  end

  defp text_to_html(text) do
    text
    |> String.replace(~r/\n/, "<br>")
    |> String.replace(~r/\s/, "&nbsp;")
    |> String.replace(~r/\t/, "&nbsp;&nbsp;&nbsp;&nbsp;")
    |> Phoenix.HTML.raw()
  end

  defp get_workspace(id) do
    Workspaces.get_workspace!(id)
  end
end
