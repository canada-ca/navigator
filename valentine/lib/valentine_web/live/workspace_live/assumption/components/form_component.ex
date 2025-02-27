defmodule ValentineWeb.WorkspaceLive.Assumption.Components.FormComponent do
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
        id="assumptions-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.dialog id="assumption-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@on_cancel)}>
          <:header_title>
            <%= if @assumption.id do %>
              {gettext("Edit Assumption")}
            <% else %>
              {gettext("New Assumption")}
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
              placeholder={gettext("Add new assumption...")}
              is_full_width
              rows="7"
              caption={
                gettext(
                  "Assumptions help you to make better decisions by identifying the things you believe to be true."
                )
              }
              is_form_control
            />
            <input type="hidden" value={@assumption.workspace_id} name="assumption[workspace_id]" />
          </:body>
          <:footer>
            <.button is_primary is_submit phx-disable-with={gettext("Saving...")}>
              {gettext("Save Assumption")}
            </.button>
            <.button phx-click={cancel_dialog("assumption-modal")}>{gettext("Cancel")}</.button>
          </:footer>
        </.dialog>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{assumption: assumption} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:changeset, fn ->
       Composer.change_assumption(assumption)
     end)}
  end

  @impl true
  def handle_event("validate", %{"assumption" => assumption_params}, socket) do
    changeset = Composer.change_assumption(socket.assigns.assumption, assumption_params)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"assumption" => assumption_params}, socket) do
    save_assumption(socket, socket.assigns.action, assumption_params)
  end

  defp save_assumption(socket, :edit, assumption_params) do
    case Composer.update_assumption(socket.assigns.assumption, assumption_params) do
      {:ok, assumption} ->
        notify_parent({:saved, assumption})

        log(
          :info,
          socket.assigns.current_user,
          "Assumption updated",
          %{
            assumption: assumption.id,
            workspace: assumption.workspace_id
          },
          "assumptions"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Assumption updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_assumption(socket, :new, assumption_params) do
    case Composer.create_assumption(assumption_params) do
      {:ok, assumption} ->
        notify_parent({:saved, assumption})

        log(
          :info,
          socket.assigns.current_user,
          "Assumption created",
          %{assumption: assumption.id, workspace: assumption.workspace_id},
          "assumptions"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Assumption created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
