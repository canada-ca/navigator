defmodule ValentineWeb.WorkspaceLive.DataFlow.Index do
  use ValentineWeb, :live_view
  use PrimerLive
  require Logger

  alias Valentine.Composer
  alias Phoenix.PubSub

  alias Valentine.Composer.DataFlowDiagram

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = Composer.get_workspace!(workspace_id)

    # Subscribe to workspace-specific updates
    if connected?(socket) do
      PubSub.subscribe(Valentine.PubSub, "workspace_dataflow:#{workspace.id}")
    end

    dfd =
      DataFlowDiagram.get(workspace_id)

    {:ok,
     socket
     |> assign(:dfd, dfd)
     |> assign(:saved, true)
     |> assign(:selected_elements, %{"nodes" => %{}, "edges" => %{}})
     |> assign(:show_threat_statement_generator, false)
     |> assign(:show_threat_statement_linker, false)
     |> assign(:touched, true)
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Data flow diagram"))
  end

  # Intercept select and unselect events
  @impl true
  def handle_event("select", %{"id" => id, "label" => label, "group" => group}, socket) do
    selected_elements = put_in(socket.assigns.selected_elements, [group, id], label)

    {:noreply,
     socket
     |> assign(:selected_elements, selected_elements)}
  end

  @impl true
  def handle_event("unselect", %{"id" => id, "group" => group}, socket) do
    {_, selected_elements} = pop_in(socket.assigns.selected_elements, [group, id])

    {:noreply,
     socket
     |> assign(:selected_elements, selected_elements)}
  end

  # Handle the event when the user clicks on the "Save" button
  @impl true
  def handle_event("save", _params, socket) do
    DataFlowDiagram.save(socket.assigns.workspace_id)

    log(
      :info,
      socket.assigns.current_user,
      "save",
      socket.assigns.workspace_id,
      "data_flow_diagram"
    )

    broadcast("workspace_dataflow:#{socket.assigns.workspace_id}", %{
      event: :saved,
      payload: %{}
    })

    {:noreply,
     socket
     |> push_event("updateGraph", %{event: "save", payload: nil})
     |> assign(:saved, true)}
  end

  # Handles the base64 encoded image data sent from the client
  @impl true
  def handle_event("export", %{"base64" => base64}, socket) do
    Composer.get_data_flow_diagram_by_workspace_id(socket.assigns.workspace_id)
    |> Composer.update_data_flow_diagram(%{raw_image: base64})

    {:noreply, socket}
  end

  # Handle generate threat statement event
  @impl true
  def handle_event("toggle_generate_threat_statement", _, socket) do
    # Save the DFD
    DataFlowDiagram.save(socket.assigns.workspace_id)

    {:noreply,
     socket
     |> assign(:show_threat_statement_generator, !socket.assigns.show_threat_statement_generator)}
  end

  # Handle link threat statement event
  @impl true
  def handle_event("toggle_link_threat_statement", _, socket) do
    # Save the DFD
    DataFlowDiagram.save(socket.assigns.workspace_id)

    {:noreply,
     socket
     |> assign(:show_threat_statement_linker, !socket.assigns.show_threat_statement_linker)}
  end

  # Handle export to Mermaid.js event
  @impl true
  def handle_event("export_mermaid", _params, socket) do
    # Redirect to the Mermaid export URL
    {:noreply,
     socket
     |> redirect(external: "/workspaces/#{socket.assigns.workspace_id}/data_flow/mermaid")}
  end

  # Local event from HTML or JS
  @impl true
  def handle_event(event, params, socket) do
    Logger.info("Local event: #{inspect(event)}, payload: #{inspect(params)}")

    params = Map.put(params, "selected_elements", socket.assigns.selected_elements)

    case Kernel.apply(Valentine.Composer.DataFlowDiagram, String.to_existing_atom(event), [
           socket.assigns.workspace_id,
           params
         ]) do
      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, reason)}

      payload ->
        broadcast("workspace_dataflow:#{socket.assigns.workspace_id}", %{
          event: event,
          payload: payload
        })

        if Map.has_key?(params, "localJs") do
          {:noreply, socket |> assign(:saved, false)}
        else
          {:noreply,
           socket
           |> push_event("updateGraph", %{
             event: event,
             payload: payload
           })
           |> assign(:touched, !socket.assigns.touched)
           |> assign(:saved, false)}
        end
    end
  end

  # Remote event from PubSub
  @impl true
  def handle_info(%{event: event, payload: payload}, socket) do
    Logger.info("Remote event: #{inspect(event)}, payload: #{inspect(payload)}")

    {:noreply,
     socket
     |> push_event("updateGraph", %{event: event, payload: payload})
     |> assign(:saved, if(event == :saved, do: true, else: false))}
  end

  # Handle info from components
  @impl true
  def handle_info({:toggle_generate_threat_statement, nil}, socket) do
    handle_event("toggle_generate_threat_statement", nil, socket)
  end

  @impl true
  def handle_info({:update_metadata, params}, socket) do
    handle_event("update_metadata", params, socket)
    {:noreply, socket}
  end

  defp broadcast(topic, payload) do
    PubSub.broadcast_from!(Valentine.PubSub, self(), topic, payload)
  end
end
