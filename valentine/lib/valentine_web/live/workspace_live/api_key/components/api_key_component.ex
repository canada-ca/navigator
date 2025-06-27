defmodule ValentineWeb.WorkspaceLive.ApiKey.Components.ApiKeyComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        id="api-keys-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.dialog id="api-key-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@patch)}>
          <:header_title>
            {gettext("Generate API Key")}
          </:header_title>
          <:body>
            <.text_input
              form={f}
              field={:label}
              form_control={
                %{
                  label: gettext("Label")
                }
              }
              class="mt-2"
              placeholder={gettext("Describe the API keys purpose. ex. 'OSCAL Integration'")}
              is_full_width
              is_form_control
            />
            <input type="hidden" value={@api_key.workspace_id} name="api_key[workspace_id]" />
            <input type="hidden" value={:active} name="api_key[status]" />
            <input type="hidden" value={@current_user} name="api_key[owner]" />
          </:body>
          <:footer>
            <.button is_primary is_submit phx-disable-with={gettext("Saving...")}>
              {gettext("Generate API Key")}
            </.button>
            <.button phx-click={cancel_dialog("api-key-modal")}>{gettext("Cancel")}</.button>
          </:footer>
        </.dialog>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{api_key: api_key} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:changeset, fn ->
       Composer.change_api_key(api_key)
     end)}
  end

  @impl true
  def handle_event("validate", %{"api_key" => api_key_params}, socket) do
    changeset = Composer.change_api_key(socket.assigns.api_key, api_key_params)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"api_key" => api_key_params}, socket) do
    save_api_key(socket, :generate, api_key_params)
  end

  defp save_api_key(socket, :generate, api_key_params) do
    case Composer.create_api_key(api_key_params) do
      {:ok, api_key} ->
        notify_parent({:saved, api_key})

        log(
          :info,
          socket.assigns.current_user,
          "API Key created",
          %{api_key: api_key.id, workspace: api_key.workspace_id},
          "api_keys"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("API Key created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
