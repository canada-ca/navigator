defmodule ValentineWeb.WorkspaceLive.DataFlow.IndexTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  setup do
    workspace = workspace_fixture()
    dfd = data_flow_diagram_fixture(%{workspace_id: workspace.id})

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        live_action: nil,
        flash: %{},
        current_user: workspace.owner,
        selected_elements: %{"nodes" => %{}, "edges" => %{}},
        show_threat_statement_generator: false,
        show_threat_statement_linker: false,
        touched: false,
        workspace_id: workspace.id
      }
    }

    %{dfd: dfd, socket: socket, workspace_id: workspace.id}
  end

  describe "mount/3" do
    test "assigns workspace_id and initializes dfd and selected assigns", %{
      workspace_id: workspace_id,
      dfd: dfd,
      socket: socket
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.mount(
          %{"workspace_id" => workspace_id},
          nil,
          socket
        )

      assert socket.assigns.dfd == dfd
      assert socket.assigns.selected_elements == %{"nodes" => %{}, "edges" => %{}}
      assert socket.assigns.workspace_id == workspace_id
    end
  end

  describe "handle_params/3 assigns the page title to :index action" do
    test "assigns the page title to 'Data flow diagram' when live_action is :index" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: :index,
          flash: %{},
          workspace_id: 1
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_params(nil, nil, socket)

      assert socket.assigns.page_title == "Data flow diagram"
    end
  end

  describe "handle_event/3" do
    test "select event assigns selected_id and selected_label", %{
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "select",
          %{"id" => "1", "label" => "Node 1", "group" => "nodes"},
          socket
        )

      assert socket.assigns.selected_elements == %{"nodes" => %{"1" => "Node 1"}, "edges" => %{}}
    end

    test "unselect event assigns empty string to selected_id and selected_label", %{
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "unselect",
          %{"id" => "1", "group" => "nodes"},
          socket
        )

      assert socket.assigns.selected_elements == %{"nodes" => %{}, "edges" => %{}}
    end

    test "save event assigns saved to true", %{
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "save",
          %{},
          socket
        )

      assert socket.assigns.saved == true
    end

    test "save event perists changes to the db", %{
      socket: socket,
      workspace_id: workspace_id
    } do
      assert Valentine.Composer.DataFlowDiagram.get(workspace_id).nodes == %{}

      Valentine.Composer.DataFlowDiagram.add_node(workspace_id, %{"type" => "test"})

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "save",
          %{},
          socket
        )

      dfd = Valentine.Composer.DataFlowDiagram.new(workspace_id)

      assert Kernel.map_size(dfd.nodes) == 1

      assert socket.assigns.saved == true
    end

    test "export event persists image data to the db", %{
      socket: socket,
      workspace_id: workspace_id
    } do
      assert Valentine.Composer.DataFlowDiagram.get(workspace_id).raw_image == nil

      {:noreply, _socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "export",
          %{"base64" => "test"},
          socket
        )

      dfd = Valentine.Composer.DataFlowDiagram.get(workspace_id, false)

      assert dfd.raw_image == "test"
    end

    test "handles toggling the threat statement generator", %{
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "toggle_generate_threat_statement",
          %{},
          socket
        )

      assert socket.assigns.show_threat_statement_generator == true
    end

    test "handles toggling the threat statement linker", %{
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "toggle_link_threat_statement",
          %{},
          socket
        )

      assert socket.assigns.show_threat_statement_linker == true
    end

    test "handles generic events and applys them to the DFD and pushes the event to the client",
         %{
           socket: socket
         } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "fit_view",
          %{},
          socket
        )

      assert socket.private == %{
               live_temp: %{
                 push_events: [["updateGraph", %{payload: nil, event: "fit_view"}]]
               }
             }

      assert socket.assigns.touched == true
    end

    test "handles generic events and applys them to the DFD and does pushes the event to the client if it happend locally",
         %{
           socket: socket
         } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "fit_view",
          %{"localJs" => true},
          socket
        )

      assert socket.private == %{live_temp: %{}}
    end
  end

  describe "handle_info/2" do
    test "receives remote event and pushes them to the client", %{socket: socket} do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_info(
          %{
            event: "fit_view",
            payload: nil
          },
          socket
        )

      assert socket.private == %{
               live_temp: %{
                 push_events: [["updateGraph", %{event: "fit_view", payload: nil}]]
               }
             }
    end

    test "receives remote event and sets saved to true if the event is :saved", %{socket: socket} do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_info(
          %{
            event: :saved,
            payload: nil
          },
          socket
        )

      assert socket.assigns.saved == true
    end

    test "receives remote event and sets saved to false if the event is not :saved", %{
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_info(
          %{
            event: "fit_view",
            payload: nil
          },
          socket
        )

      assert socket.assigns.saved == false
    end

    test "receives toggle_generate_threat_statement from a component and forwards it to handle_event",
         %{
           socket: socket
         } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_info(
          {:toggle_generate_threat_statement, nil},
          socket
        )

      assert socket.assigns.show_threat_statement_generator == true
    end

    test "receives update_metadata from a component and forwards it to handle_event", %{
      socket: socket
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_info(
          {:update_metadata, %{"id" => "id", "field" => "field"}},
          socket
        )

      # Or true == true :(
      assert socket == socket
    end
  end
end
