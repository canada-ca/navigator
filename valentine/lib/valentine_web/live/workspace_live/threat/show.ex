defmodule ValentineWeb.WorkspaceLive.Threat.Show do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Threat
  alias Valentine.Repo

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace_id)

    {:ok,
     socket
     |> assign(:active_type, nil)
     |> assign(:errors, nil)
     |> assign(:toggle_goals, false)
     |> assign(:workspace_id, workspace_id)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create new threat statement")
    |> assign(:threat, %Threat{})
    |> assign(:changes, %{workspace_id: socket.assigns.workspace_id})
  end

  defp apply_action(socket, :edit, %{"id" => id} = _params) do
    threat =
      Composer.get_threat!(id)
      |> Repo.preload([:assumptions, :mitigations])

    socket
    |> assign_preloads()
    |> assign(:page_title, "Edit threat statement")
    |> assign(:threat, threat)
    |> assign(:changes, Map.from_struct(threat))
  end

  def handle_event("save", _params, socket) do
    if socket.assigns.threat.id do
      update_existing_threat(socket)
    else
      create_new_threat(socket)
    end
  end

  @impl true
  def handle_event("show_context", %{"field" => field, "type" => type}, socket) do
    field = String.to_existing_atom(field)

    context =
      ValentineWeb.WorkspaceLive.Threat.Components.StatementExamples.content(field)

    {:noreply,
     socket
     |> assign(:active_field, field)
     |> assign(:active_type, type)
     |> assign(:context, context)}
  end

  @impl true
  def handle_event("toggle_goals", _params, socket) do
    {:noreply, assign(socket, :toggle_goals, !socket.assigns.toggle_goals)}
  end

  @impl true
  def handle_event("update_field", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> assign(:changes, Map.put(socket.assigns.changes, socket.assigns.active_field, value))}
  end

  @impl true
  def handle_event("update_field", %{"_target" => [field]} = params, socket) do
    value =
      cond do
        is_list(params[field]) ->
          params[field]
          |> Enum.reject(&(&1 == "false"))
          |> Enum.map(&String.to_existing_atom/1)

        field == "comments" ->
          params[field]

        is_binary(params[field]) ->
          Phoenix.Naming.underscore(params[field])

        true ->
          nil
      end

    {:noreply,
     socket
     |> assign(
       :changes,
       Map.put(socket.assigns.changes, String.to_existing_atom(field), value)
     )}
  end

  @impl true
  def handle_event("remove_assumption", %{"id" => id}, socket) do
    threat = socket.assigns.threat
    assumption = Composer.get_assumption!(id)

    {:ok, threat} = Composer.remove_assumption_from_threat(threat, assumption)

    {:noreply, assign(socket, :threat, threat)}
  end

  @impl true
  def handle_event("remove_mitigation", %{"id" => id}, socket) do
    threat = socket.assigns.threat
    mitigation = Composer.get_mitigation!(id)

    {:ok, threat} = Composer.remove_mitigation_from_threat(threat, mitigation)

    {:noreply, assign(socket, :threat, threat)}
  end

  @impl true
  def handle_info({"update_field", params}, socket),
    do: handle_event("update_field", params, socket)

  def handle_info({"assumptions", :selected_item, selected_item}, socket) do
    threat = socket.assigns.threat
    assumption = Composer.get_assumption!(selected_item.id)

    {:ok, threat} = Composer.add_assumption_to_threat(threat, assumption)

    {:noreply, assign(socket, :threat, threat)}
  end

  def handle_info({"mitigations", :selected_item, selected_item}, socket) do
    threat = socket.assigns.threat
    mitigation = Composer.get_mitigation!(selected_item.id)

    {:ok, threat} = Composer.add_mitigation_to_threat(threat, mitigation)

    {:noreply, assign(socket, :threat, threat)}
  end

  defp update_existing_threat(socket) do
    case Composer.update_threat(socket.assigns.threat, socket.assigns.changes) do
      {:ok, threat} ->
        broadcast_threat_change(threat, "threat_updated")

        {:noreply,
         socket
         |> put_flash(:info, "Threat updated successfully")
         |> push_navigate(to: ~p"/workspaces/#{threat.workspace_id}/threats/#{threat.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :errors, changeset.errors)}
    end
  end

  defp create_new_threat(socket) do
    case Composer.create_threat(socket.assigns.changes) do
      {:ok, threat} ->
        broadcast_threat_change(threat, "threat_created")

        {:noreply,
         socket
         |> put_flash(:info, "Threat created successfully")
         |> push_navigate(to: ~p"/workspaces/#{threat.workspace_id}/threats/#{threat.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :errors, changeset.errors)}
    end
  end

  defp assign_preloads(socket) do
    assumptions = Composer.list_assumptions_by_workspace(socket.assigns.workspace_id)
    mitigations = Composer.list_mitigations_by_workspace(socket.assigns.workspace_id)

    socket
    |> assign(:assumptions, assumptions)
    |> assign(:mitigations, mitigations)
  end

  defp broadcast_threat_change(threat, event) do
    ValentineWeb.Endpoint.broadcast(
      "workspace_" <> threat.workspace_id,
      event,
      %{}
    )
  end
end
