defmodule ValentineWeb.WorkspaceLive.ReferencePacks.Components.ImportComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form id="upload-form" phx-submit="save" phx-change="validate" phx-target={@myself}>
        <.dialog
          id="reference-packs-import-modal"
          is_backdrop
          is_show
          is_wide
          on_cancel={JS.patch(@patch)}
        >
          <:header_title>
            Import reference pack
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
              Import reference pack
            </.button>
            <.button phx-click={cancel_dialog("reference-packs-import-modal")}>Cancel</.button>
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
      consume_uploaded_entries(socket, :import, fn %{path: path}, _entry ->
        import_file(path)
      end)

    if result == :ok do
      log(
        :info,
        socket.assigns.current_user,
        "import",
        %{workspace: socket.assigns.workspace.id},
        "reference_pack"
      )

      {:noreply,
       socket
       |> put_flash(:info, "Reference pack imported successfully")
       |> push_navigate(to: socket.assigns.patch)}
    else
      {:noreply,
       socket
       |> assign(:upload_errors, [msg])}
    end
  end

  defp build_reference_pack(data) do
    common = %{
      collection_id:
        Ecto.UUID.generate()
        |> to_string(),
      collection_name: data["name"],
      description: data["description"],
      name: data["name"],
      collection_type: nil,
      data: nil
    }

    # Create all the assumptions in this reference pack
    (data["assumptions"] || [])
    |> Enum.map(fn assumption ->
      %{
        common
        | collection_type: :assumption,
          data: assumption
      }
    end)
    |> Enum.each(&Composer.create_reference_pack_item/1)

    # Create all the threats in this reference pack
    (data["threats"] || [])
    |> Enum.map(fn threat ->
      %{
        common
        | collection_type: :threat,
          data: threat
      }
    end)
    |> Enum.each(&Composer.create_reference_pack_item/1)

    # Create all the mitigations in this reference pack
    (data["mitigations"] || [])
    |> Enum.map(fn mitigation ->
      %{
        common
        | collection_type: :mitigation,
          data: mitigation
      }
    end)
    |> Enum.each(&Composer.create_reference_pack_item/1)

    {:ok, :ok}
  end

  defp import_file(path) do
    with {:ok, json} <- File.read(path),
         {:ok, data} <- validate(json),
         {:ok, result} <- build_reference_pack(data) do
      {:ok, {:ok, result}}
    else
      {:error, msg} when is_binary(msg) -> {:ok, {:error, msg}}
      {:error, _} -> {:ok, {:error, "Invalid file"}}
    end
  end

  defp upload_error_to_string(:too_many_files), do: "You can only upload one file at a time"
  defp upload_error_to_string(:too_large), do: "The file is too large"
  defp upload_error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp upload_error_to_string(:external_client_failure), do: "Something went terribly wrong"

  def validate(data) do
    with {:ok, json} <- Jason.decode(data),
         {:ok, data} <- validate_required_fields(json) do
      {:ok, data}
    else
      {:missing_fields, fields} -> {:error, "Missing required fields: #{Enum.join(fields, ", ")}"}
      {:error, _} -> {:error, "Invalid JSON"}
    end
  end

  defp validate_required_fields(data) do
    data =
      if Map.has_key?(data, "workspace") do
        data["workspace"]
      else
        data
      end

    required_keys =
      ~w(name)

    missing_keys = Enum.filter(required_keys, &(!Map.has_key?(data, &1)))

    case missing_keys do
      [] -> {:ok, data}
      keys -> {:missing_fields, keys}
    end
  end
end
