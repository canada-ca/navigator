defmodule ValentineWeb.WorkspaceLive.ApplicationInformation.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer.Documents

  alias Valentine.Composer.Workspaces
  alias Phoenix.PubSub

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)

    # Subscribe to workspace-specific updates
    if connected?(socket) do
      PubSub.subscribe(Valentine.PubSub, "workspace_application_information:#{workspace.id}")
    end

    socket =
      Valentine.Composer.ApplicationInformation.get_cache(workspace.id)
      |> Enum.reduce(socket, fn ops, socket ->
        socket
        |> push_event("updateQuill", %{event: "text_change", payload: %{ops: ops}})
      end)

    {:ok,
     socket
     |> assign(
       :application_information,
       workspace.application_information || %Valentine.Composer.ApplicationInformation{}
     )
     |> assign(:touched, false)
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Application information"))
  end

  @impl true
  def handle_info({:execute_skill, %{"data" => data, "type" => type}}, socket) do
    with_write(socket, fn socket ->
      data = if data != "", do: Jason.decode!(data), else: %{}

      case {type, data} do
        {"insert", %{"ops" => ops}} ->
          apply_quill_change(%{"ops" => ops}, socket)

        _ ->
          {:noreply, socket}
      end
    end)
  end

  # Local change
  @impl true
  def handle_info({:quill_change, delta}, socket) do
    with_write(socket, &apply_quill_change(delta, &1))
  end

  # Remote edit change
  @impl true
  def handle_info(%{event: :quill_change, payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:touched, true)
     |> push_event("updateQuill", %{event: "text_change", payload: payload})}
  end

  # Remote save button clicked
  @impl true
  def handle_info(%{event: :quill_saved}, socket) do
    workspace = get_workspace(socket.assigns.workspace_id)

    {:noreply,
     socket
     |> assign(:touched, false)
     |> push_event("updateQuill", %{
       event: "blob_change",
       payload: workspace.application_information.content
     })}
  end

  # Save button clicked
  @impl true
  def handle_info({:quill_save, content}, socket) do
    with_write(socket, fn socket ->
      # Create or update new application information
      workspace = get_workspace(socket.assigns.workspace_id)

      case workspace.application_information do
        nil ->
          log(
            :info,
            socket.assigns.current_user,
            "created",
            workspace.id,
            "application information"
          )

          Documents.create_application_information(%{
            content: content,
            workspace_id: workspace.id
          })

        _ ->
          log(
            :info,
            socket.assigns.current_user,
            "updated",
            workspace.id,
            "application information"
          )

          Documents.update_application_information(workspace.application_information, %{
            content: content
          })
      end

      Valentine.Composer.ApplicationInformation.flush_cache(workspace.id)

      broadcast("workspace_application_information:#{socket.assigns.workspace_id}", %{
        event: :quill_saved
      })

      {:noreply, assign(socket, :touched, false)}
    end)
  end

  defp apply_quill_change(delta, socket) do
    Valentine.Composer.ApplicationInformation.push_cache(socket.assigns.workspace_id, [
      delta["ops"]
    ])

    broadcast("workspace_application_information:#{socket.assigns.workspace_id}", %{
      event: :quill_change,
      payload: delta
    })

    {:noreply, assign(socket, :touched, true)}
  end

  defp broadcast(topic, payload) do
    PubSub.broadcast_from!(Valentine.PubSub, self(), topic, payload)
  end

  defp get_workspace(workspace_id) do
    Workspaces.get_workspace!(workspace_id, [:application_information])
  end

  defp with_write(socket, fun) do
    case ValentineWeb.Helpers.WorkspaceAuthorizationHelper.authorize(socket, :write) do
      {:ok, _workspace} -> fun.(socket)
      {:error, socket} -> {:noreply, socket}
    end
  end
end
