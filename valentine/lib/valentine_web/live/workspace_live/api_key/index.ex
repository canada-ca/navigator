defmodule ValentineWeb.WorkspaceLive.ApiKey.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = Composer.get_workspace!(workspace_id)
    api_keys = Composer.list_api_keys_by_workspace(workspace.id)

    {:ok,
     socket
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:permission, socket.assigns.workspace_permission)
     |> assign(:api_keys, api_keys)
     |> assign(:recent_api_key, nil)
     |> assign(:workspace, workspace)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :generate, _params) do
    socket
    |> assign(:page_title, gettext("Generate API Key"))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("API Keys"))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Composer.get_api_key(id) do
      nil ->
        {:noreply, socket |> put_flash(:error, gettext("API key not found"))}

      api_key ->
        case Composer.delete_api_key(api_key) do
          {:ok, _} ->
            log(
              :info,
              socket.assigns.current_user,
              "Deleted api_key",
              %{
                workspace_id: socket.assigns.workspace_id,
                api_key_id: api_key.id
              },
              "api_key"
            )

            {:noreply,
             socket
             |> put_flash(:info, gettext("API key deleted successfully"))
             |> assign(
               :api_keys,
               Composer.list_api_keys_by_workspace(socket.assigns.workspace_id)
             )
             |> assign(:recent_api_key, nil)}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, gettext("Failed to delete API key"))}
        end
    end
  end

  @impl true
  def handle_event("flush_api_key", _, socket) do
    {:noreply,
     socket
     |> assign(:recent_api_key, nil)}
  end

  @impl true
  def handle_info(
        {_, {:saved, api_key}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(
       :api_keys,
       Composer.list_api_keys_by_workspace(socket.assigns.workspace_id)
     )
     |> assign(:recent_api_key, api_key)}
  end
end
