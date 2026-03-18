defmodule ValentineWeb.WorkspaceLive.DataFlow.IndexTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
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
        dfd: dfd,
        saved: true,
        selected_elements: %{"nodes" => %{}, "edges" => %{}},
        show_threat_statement_generator: false,
        show_threat_statement_linker: false,
        show_mermaid_import: false,
        mermaid_import_source: "",
        mermaid_import_preview: nil,
        mermaid_import_error: nil,
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

    test "opens the Mermaid import modal", %{socket: socket} do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "open_mermaid_import",
          %{},
          socket
        )

      assert socket.assigns.show_mermaid_import == true
      assert socket.assigns.mermaid_import_preview == nil
    end

    test "previews Mermaid import warnings without mutating the diagram", %{
      socket: socket,
      workspace_id: workspace_id
    } do
      source = "stateDiagram-v2\nnode_1 : External User"

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "preview_mermaid_import",
          %{"mermaid_import" => %{"source" => source}},
          socket
        )

      assert socket.assigns.show_mermaid_import == true
      assert socket.assigns.mermaid_import_error == nil
      assert socket.assigns.mermaid_import_preview.summary.nodes == 1
      assert Valentine.Composer.DataFlowDiagram.get(workspace_id).nodes == %{}
    end

    test "previewing invalid Mermaid keeps the diagram unchanged and sets an error", %{
      socket: socket,
      workspace_id: workspace_id
    } do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "preview_mermaid_import",
          %{"mermaid_import" => %{"source" => "flowchart LR\nA -->"}},
          socket
        )

      assert socket.assigns.mermaid_import_error == "Unsupported Mermaid flowchart syntax"
      assert socket.assigns.mermaid_import_preview == nil
      assert Valentine.Composer.DataFlowDiagram.get(workspace_id).nodes == %{}
    end

    test "confirms Mermaid import and refreshes the graph", %{
      socket: socket,
      workspace_id: workspace_id
    } do
      {:noreply, preview_socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "preview_mermaid_import",
          %{"mermaid_import" => %{"source" => "stateDiagram-v2\nnode_1 : External User"}},
          socket
        )

      {:noreply, confirmed_socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "confirm_mermaid_import",
          %{},
          preview_socket
        )

      assert confirmed_socket.assigns.saved == true
      assert confirmed_socket.assigns.show_mermaid_import == false
      assert confirmed_socket.assigns.dfd.nodes != %{}

      assert %{live_temp: %{push_events: [["updateGraph", payload]]}} = confirmed_socket.private
      assert payload.event == "refresh_graph"
      assert payload.payload.edges == []
      assert length(payload.payload.nodes) == 1

      persisted = Valentine.Composer.DataFlowDiagram.get(workspace_id, false)
      assert map_size(persisted.nodes) == 1
    end

    test "closing Mermaid import resets preview state", %{socket: socket} do
      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "open_mermaid_import",
          %{},
          socket
        )

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_event(
          "close_mermaid_import",
          %{},
          %{
            socket
            | assigns: Map.put(socket.assigns, :mermaid_import_preview, %{summary: %{nodes: 1}})
          }
        )

      assert socket.assigns.show_mermaid_import == false
      assert socket.assigns.mermaid_import_preview == nil
      assert socket.assigns.mermaid_import_source == ""
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
      socket: socket,
      workspace_id: workspace_id
    } do
      node = Valentine.Composer.DataFlowDiagram.add_node(workspace_id, %{"type" => "process"})

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_info(
          {:update_metadata,
           %{
             "id" => node["data"]["id"],
             "field" => "linked_threats",
             "value" => ["threat-1"]
           }},
          socket
        )

      assert socket.assigns.saved == false
      assert socket.assigns.touched == true

      assert socket.private == %{
               live_temp: %{
                 push_events: [
                   [
                     "updateGraph",
                     %{
                       event: "update_metadata",
                       payload: %{
                         "field" => "linked_threats",
                         "id" => node["data"]["id"],
                         "value" => ["threat-1"]
                       }
                     }
                   ]
                 ]
               }
             }
    end

    test "receives Mermaid import broadcasts and refreshes the graph", %{
      socket: socket,
      workspace_id: workspace_id
    } do
      imported_dfd =
        Valentine.Composer.DataFlowDiagram.replace_diagram(workspace_id, %{
          nodes: %{
            "node-import-1" => %{
              "data" => %{
                "id" => "node-import-1",
                "data_tags" => [],
                "description" => nil,
                "label" => "Imported User",
                "linked_threats" => [],
                "out_of_scope" => "false",
                "parent" => nil,
                "security_tags" => [],
                "technology_tags" => [],
                "type" => "actor"
              },
              "grabbable" => "true",
              "position" => %{"x" => 0, "y" => 0}
            }
          },
          edges: %{}
        })

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.DataFlow.Index.handle_info(
          %{event: "import_mermaid", payload: imported_dfd},
          socket
        )

      assert socket.assigns.saved == true
      assert socket.assigns.dfd.nodes == imported_dfd.nodes
      assert %{live_temp: %{push_events: [["updateGraph", payload]]}} = socket.private
      assert payload.event == "refresh_graph"
      assert payload.payload.edges == []
      assert length(payload.payload.nodes) == 1
    end
  end

  describe "rendered LiveView import flow" do
    test "opens, previews, and cancels Mermaid import", %{conn: conn} do
      workspace = workspace_fixture()

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.id}/data_flow")

      assert view |> element("#open-mermaid-import") |> render_click() =~ "Import Mermaid diagram"

      preview_html =
        view
        |> form("#mermaid-import-form",
          mermaid_import: %{source: "stateDiagram-v2\nnode_1 : User"}
        )
        |> render_submit()

      assert preview_html =~ "Import summary"
      assert preview_html =~ "Warnings"

      cancel_html = view |> element("button", "Cancel") |> render_click()
      refute cancel_html =~ "Import summary"
    end

    test "imports Mermaid through the editor and exports canonical Mermaid", %{conn: conn} do
      workspace = workspace_fixture()

      # Seed an existing diagram so the preview path also exercises replacement warnings.
      Valentine.Composer.DataFlowDiagram.add_node(workspace.id, %{"type" => "process"})
      Valentine.Composer.DataFlowDiagram.save(workspace.id)

      mermaid = """
      stateDiagram-v2
          node_101890 : Priviliged user
          node_90306 : Fine-grained personal access token
          state GitHub {
              node_93122 : GitHub Authentication
              node_7875 : Private repositories
          }
          node_101890 --> node_90306 : Token access
          node_90306 --> node_93122 : Assumed role access
          node_93122 --> node_7875 : Authenticated access
      """

      conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: workspace.owner})

      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.id}/data_flow")

      preview_html =
        view
        |> element("#open-mermaid-import")
        |> render_click()

      assert preview_html =~ "Import Mermaid diagram"

      preview_html =
        view
        |> form("#mermaid-import-form", mermaid_import: %{source: mermaid})
        |> render_submit()

      assert preview_html =~ "Import summary"
      assert preview_html =~ "replace the current diagram"
      assert preview_html =~ "metadata"

      confirm_html = view |> element("#confirm-mermaid-import") |> render_click()

      assert confirm_html =~ "Mermaid diagram imported successfully"
      refute confirm_html =~ "Import summary"

      export_conn =
        Phoenix.ConnTest.build_conn()
        |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
        |> get(~p"/workspaces/#{workspace.id}/data_flow/mermaid")

      assert export_conn.status == 200
      assert String.starts_with?(export_conn.resp_body, "stateDiagram-v2")
      assert export_conn.resp_body =~ "node_101890 : Priviliged user"
      assert export_conn.resp_body =~ "node_90306 : Fine-grained personal access token"
      assert export_conn.resp_body =~ "state GitHub {"
      assert export_conn.resp_body =~ "node_93122 : GitHub Authentication"
      assert export_conn.resp_body =~ "node_7875 : Private repositories"
      assert export_conn.resp_body =~ "node_101890 --> node_90306 : Token access"
      assert export_conn.resp_body =~ "node_90306 --> node_93122 : Assumed role access"
      assert export_conn.resp_body =~ "node_93122 --> node_7875 : Authenticated access"

      dfd = Valentine.Composer.DataFlowDiagram.get(workspace.id, false)
      assert map_size(dfd.nodes) == 5
      assert map_size(dfd.edges) == 3
    end
  end
end
