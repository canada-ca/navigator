defmodule ValentineWeb.WorkspaceLive.ImportComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias ValentineWeb.WorkspaceLive.Import.Helper

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form id="upload-form" phx-submit="save" phx-change="validate" phx-target={@myself}>
        <.dialog
          id="workspace-import-modal"
          is_backdrop
          is_show
          is_wide
          on_cancel={JS.patch(~p"/workspaces")}
        >
          <:header_title>
            {gettext("Import Workspace")}
          </:header_title>
          <:body>
            <.live_file_input upload={@uploads.import} />
            <div
              :for={err <- upload_errors(@uploads.import)}
              class="FormControl-inlineValidation FormControl-inlineValidation--error"
            >
              {upload_error_to_string(err)}
            </div>
            <div
              :for={msg <- @upload_errors}
              class="FormControl-inlineValidation FormControl-inlineValidation--error"
            >
              {msg}
            </div>
          </:body>
          <:footer>
            <.button is_primary is_submit phx-disable-with="Importing...">
              {gettext("Import Workspace")}
            </.button>
            <.button phx-click={cancel_dialog("workspace-import-modal")}>{gettext("Cancel")}</.button>
          </:footer>
        </.dialog>
      </form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:upload_errors, [])
     |> assign(:uploaded_file, nil)
     |> allow_upload(:import, accept: ~w(.json), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    [{result, msg}] =
      consume_uploaded_entries(socket, :import, fn %{path: path}, %{client_name: client_name} ->
        Helper.import_file(path, client_name, socket.assigns.current_user)
      end)

    if result == :ok do
      log(:info, socket.assigns.current_user, "imported", msg, "workspace")

      {:noreply,
       socket
       |> put_flash(:info, "Workspace imported successfully")
       |> push_navigate(to: socket.assigns.patch)}
    else
      {:noreply,
       socket
       |> assign(:upload_errors, [msg])}
    end
  end

  defp upload_error_to_string(:too_many_files),
    do: gettext("You can only upload one file at a time")

  defp upload_error_to_string(:too_large), do: gettext("The file is too large")

  defp upload_error_to_string(:not_accepted),
    do: gettext("You have selected an unacceptable file type")

  defp upload_error_to_string(:external_client_failure),
    do: gettext("Something went terribly wrong")
end
