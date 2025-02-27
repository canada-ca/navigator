defmodule ValentineWeb.WorkspaceLive.Mitigation.Components.FormComponent do
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
        id="mitigations-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.dialog id="mitigation-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@on_cancel)}>
          <:header_title>
            <%= if @mitigation.id do %>
              {gettext("Edit Mitigation")}
            <% else %>
              {gettext("New Mitigation")}
            <% end %>
          </:header_title>
          <:body>
            <.textarea
              form={f}
              field={:content}
              form_control={
                %{
                  label: gettext("Content")
                }
              }
              class="mt-2"
              placeholder={gettext("Add new mitigation...")}
              is_full_width
              rows="7"
              caption={
                gettext(
                  "Mitigations are actions taken to reduce the likelihood of a threat exploiting a vulnerability."
                )
              }
              is_form_control
            />
            <input type="hidden" value={@mitigation.workspace_id} name="mitigation[workspace_id]" />
          </:body>
          <:footer>
            <.button is_primary is_submit phx-disable-with={gettext("Saving...")}>
              {gettext("Save Mitigation")}
            </.button>
            <.button phx-click={cancel_dialog("mitigation-modal")}>{gettext("Cancel")}</.button>
          </:footer>
        </.dialog>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{mitigation: mitigation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:changeset, fn ->
       Composer.change_mitigation(mitigation)
     end)}
  end

  @impl true
  def handle_event("validate", %{"mitigation" => mitigation_params}, socket) do
    changeset = Composer.change_mitigation(socket.assigns.mitigation, mitigation_params)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"mitigation" => mitigation_params}, socket) do
    save_mitigation(socket, socket.assigns.action, mitigation_params)
  end

  defp save_mitigation(socket, :edit, mitigation_params) do
    case Composer.update_mitigation(socket.assigns.mitigation, mitigation_params) do
      {:ok, mitigation} ->
        notify_parent({:saved, mitigation})

        log(
          :info,
          socket.assigns.current_user,
          "update",
          %{mitigation: mitigation.id, workspace: mitigation.workspace_id},
          "mitigation"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Mitigation updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_mitigation(socket, :new, mitigation_params) do
    case Composer.create_mitigation(mitigation_params) do
      {:ok, mitigation} ->
        notify_parent({:saved, mitigation})

        log(
          :info,
          socket.assigns.current_user,
          "create",
          %{mitigation: mitigation.id, workspace: mitigation.workspace_id},
          "mitigation"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Mitigation created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
