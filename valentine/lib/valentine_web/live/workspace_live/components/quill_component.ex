defmodule ValentineWeb.WorkspaceLive.Components.QuillComponent do
  use ValentineWeb, :live_component

  use PrimerLive

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-hook="Quill" id="quill-holder" data-read-only={to_string(!@editable)}>
      <div id="quill-editor">{Phoenix.HTML.raw(@content)}</div>
    </div>
    """
  end

  @impl true
  def handle_event("quill-change", %{"delta" => delta}, socket) do
    with_write(socket, fn socket ->
      send(self(), {:quill_change, delta})
      {:noreply, socket}
    end)
  end

  @impl true
  def handle_event("quill-save", %{"content" => content}, socket) do
    with_write(socket, fn socket ->
      send(self(), {:quill_save, content})
      {:noreply, socket}
    end)
  end

  defp with_write(socket, fun) do
    case ValentineWeb.Helpers.WorkspaceAuthorizationHelper.authorize_component(
           socket,
           socket.assigns.workspace_id,
           :write
         ) do
      {:ok, _workspace} -> fun.(socket)
      {:error, socket} -> {:noreply, socket}
    end
  end
end
