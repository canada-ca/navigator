defmodule ValentineWeb.WorkspaceLive.Threat.Show do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Assumption
  alias Valentine.Composer.Mitigation
  alias Valentine.Composer.Threat
  alias Valentine.Repo

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)

    ValentineWeb.Endpoint.subscribe("workspace_" <> workspace.id)

    {:ok,
     socket
     |> assign(:active_type, nil)
     |> assign(:errors, nil)
     |> assign(:toggle_goals, false)
     |> assign(:workspace_id, workspace.id)
     |> assign(:workspace, workspace)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("Create new threat statement"))
    |> assign(:threat, %Threat{})
    |> assign(:changes, %{workspace_id: socket.assigns.workspace_id})
  end

  defp apply_action(socket, :edit, %{"id" => id} = _params) do
    workspace = get_workspace(socket.assigns.workspace_id)

    threat =
      Composer.get_threat!(id)
      |> Repo.preload([:assumptions, :mitigations])

    socket
    |> assign(:assumptions, workspace.assumptions)
    |> assign(:mitigations, workspace.mitigations)
    |> assign(:page_title, gettext("Edit threat statement"))
    |> assign(:threat, threat)
    |> assign(:changes, Map.from_struct(threat))
  end

  defp apply_action(socket, :new_assumption, params) do
    apply_action(socket, :edit, params)
    |> assign(:assumption, %Assumption{workspace_id: socket.assigns.workspace_id})
  end

  defp apply_action(socket, :new_mitigation, params) do
    apply_action(socket, :edit, params)
    |> assign(:mitigation, %Mitigation{workspace_id: socket.assigns.workspace_id})
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
  def handle_info(
        {_, {:saved, assumption = %Assumption{}}},
        socket
      ) do
    threat = socket.assigns.threat
    {:ok, threat} = Composer.add_assumption_to_threat(threat, assumption)

    {:noreply, assign(socket, :threat, threat)}
  end

  def handle_info(
        {_, {:saved, mitigation = %Mitigation{}}},
        socket
      ) do
    threat = socket.assigns.threat
    {:ok, threat} = Composer.add_mitigation_to_threat(threat, mitigation)

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

        log(
          :info,
          socket.assigns.current_user,
          "update",
          %{threat: threat.id, workspace: threat.workspace_id},
          "threat"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Threat updated successfully"))
         |> push_navigate(to: ~p"/workspaces/#{threat.workspace_id}/threats/#{threat.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :errors, changeset.errors)}
    end
  end

  defp create_new_threat(socket) do
    case Composer.create_threat(socket.assigns.changes) do
      {:ok, threat} ->
        broadcast_threat_change(threat, "threat_created")

        log(
          :info,
          socket.assigns.current_user,
          "create",
          %{threat: threat.id, workspace: threat.workspace_id},
          "threat"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Threat created successfully"))
         |> push_navigate(to: ~p"/workspaces/#{threat.workspace_id}/threats/#{threat.id}")}

        {:noreply,
         socket
         |> put_flash(:info, gettext("Threat created successfully"))
         |> push_navigate(to: ~p"/workspaces/#{threat.workspace_id}/threats/#{threat.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :errors, changeset.errors)}
    end
  end

  def get_dfd_data(workspace_id, :threat_source) do
    case Valentine.Composer.DataFlowDiagram.get(workspace_id) do
      nil ->
        []

      dfd ->
        dfd
        |> Map.get(:nodes)
        |> Map.values()
        |> Enum.filter(&(&1["data"]["type"] == "actor"))
        |> Enum.map(& &1["data"]["label"])
    end
  end

  def get_dfd_data(workspace_id, :impacted_assets) do
    case Valentine.Composer.DataFlowDiagram.get(workspace_id) do
      nil ->
        []

      dfd ->
        dfd
        |> Map.get(:nodes)
        |> Map.values()
        |> Enum.filter(&(&1["data"]["type"] == "process" || &1["data"]["type"] == "datastore"))
        |> Enum.map(& &1["data"]["label"])
    end
  end

  def get_dfd_data(_, _), do: []

  def get_workspace(id) do
    Composer.get_workspace!(id, [:assumptions, :mitigations])
  end

  defp broadcast_threat_change(threat, event) do
    ValentineWeb.Endpoint.broadcast(
      "workspace_" <> threat.workspace_id,
      event,
      %{}
    )
  end
end
