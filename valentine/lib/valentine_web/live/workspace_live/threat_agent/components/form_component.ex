defmodule ValentineWeb.WorkspaceLive.ThreatAgent.Components.FormComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.DeliberateThreatLevel

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        id="threat-agents-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.dialog id="threat-agent-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@on_cancel)}>
          <:header_title>
            <%= if @threat_agent.id do %>
              {gettext("Edit Threat Agent")}
            <% else %>
              {gettext("New Threat Agent")}
            <% end %>
          </:header_title>
          <:body>
            <.text_input
              form={f}
              field={:name}
              form_control={%{label: gettext("Name")}}
              class="my-2"
              is_full_width
              is_form_control
            />

            <.text_input
              form={f}
              field={:agent_class}
              form_control={%{label: gettext("Threat Agent Class")}}
              class="my-2"
              is_full_width
              is_form_control
            />

            <.text_input
              form={f}
              field={:capability}
              form_control={%{label: gettext("Capability")}}
              class="my-2"
              is_full_width
              is_form_control
            />

            <.text_input
              form={f}
              field={:motivation}
              form_control={%{label: gettext("Motivation")}}
              class="my-2"
              is_full_width
              is_form_control
            />

            <.select
              form={f}
              field={:td_level}
              options={[[key: gettext("Not set"), value: ""]] ++ td_level_options()}
              form_control={%{label: gettext("Deliberate Threat Level")}}
              is_form_control
            />

            <input type="hidden" value={@threat_agent.workspace_id} name="threat_agent[workspace_id]" />
          </:body>
          <:footer>
            <.button is_primary is_submit phx-disable-with={gettext("Saving...")}>
              {gettext("Save Threat Agent")}
            </.button>
            <.button phx-click={cancel_dialog("threat-agent-modal")}>{gettext("Cancel")}</.button>
          </:footer>
        </.dialog>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{threat_agent: threat_agent} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:changeset, fn ->
       Composer.change_threat_agent(threat_agent)
     end)}
  end

  @impl true
  def handle_event("validate", %{"threat_agent" => threat_agent_params}, socket) do
    changeset = Composer.change_threat_agent(socket.assigns.threat_agent, threat_agent_params)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"threat_agent" => threat_agent_params}, socket) do
    save_threat_agent(socket, socket.assigns.action, threat_agent_params)
  end

  defp save_threat_agent(socket, :edit, threat_agent_params) do
    case Composer.update_threat_agent(socket.assigns.threat_agent, threat_agent_params) do
      {:ok, threat_agent} ->
        notify_parent({:saved, threat_agent})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Threat Agent updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_threat_agent(socket, :new, threat_agent_params) do
    case Composer.create_threat_agent(threat_agent_params) do
      {:ok, threat_agent} ->
        notify_parent({:saved, threat_agent})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Threat Agent created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp td_level_options do
    Enum.map(DeliberateThreatLevel.options(), fn {label, value} -> [key: label, value: value] end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
