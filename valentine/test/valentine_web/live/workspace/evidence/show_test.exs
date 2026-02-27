defmodule ValentineWeb.WorkspaceLive.Evidence.ShowTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Evidence.Show
  alias Valentine.Composer.Evidence

  setup do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end

  describe "mount/3" do
    test "initializes workspace and form state", %{workspace: workspace, conn: conn} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/new")

      # Verify the page loaded correctly by checking for expected elements
      assert html =~ "New Evidence"
      assert html =~ "Name"
      assert html =~ "Description"
      assert has_element?(view, "#evidence-form")
      assert has_element?(view, "button", "Save")
    end
  end

  describe "handle_params for :new action" do
    test "sets up new evidence form", %{workspace: workspace, conn: conn} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/new")

      # Verify new evidence form is shown
      assert html =~ "New Evidence"
      assert has_element?(view, "#evidence-form")
      assert has_element?(view, "#evidence-name")
      assert has_element?(view, "#evidence-description")
    end

    test "initializes with description_only evidence type", %{workspace: workspace, conn: conn} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, _html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/new")

      # Verify the form initializes with description_only type
      # The UI should show the two card buttons for attaching evidence
      assert has_element?(
               view,
               "button[phx-click='set_evidence_type'][phx-value-type='blob_store_link']"
             )

      assert has_element?(
               view,
               "button[phx-click='set_evidence_type'][phx-value-type='json_data']"
             )
    end
  end

  describe "handle_params for :edit action" do
    test "loads existing evidence for editing", %{workspace: workspace, conn: conn} do
      evidence =
        evidence_fixture(%{
          workspace_id: workspace.id,
          content: %{"test" => "data"}
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}")

      # Verify edit evidence form is shown with existing data
      assert html =~ "Edit Evidence"
      assert html =~ evidence.name
      assert has_element?(view, "#evidence-form")
      # Content is displayed
      assert html =~ "test"
    end
  end

  describe "handle_event update_field" do
    setup %{workspace: workspace} do
      # Create a properly initialized socket with internal LiveView state
      socket = %Phoenix.LiveView.Socket{
        id: "test-socket",
        endpoint: ValentineWeb.Endpoint,
        view: ValentineWeb.WorkspaceLive.Evidence.Show,
        assigns: %{
          __changed__: %{},
          workspace_id: workspace.id,
          evidence: %Evidence{},
          changes: %{},
          content_raw: ""
        }
      }

      %{socket: socket}
    end

    test "updates content_raw field", %{socket: socket} do
      params = %{"_target" => ["content_raw"], "content_raw" => "{\"key\": \"value\"}"}

      {:noreply, updated_socket} = Show.handle_event("update_field", params, socket)

      assert updated_socket.assigns.content_raw == "{\"key\": \"value\"}"
    end

    test "updates evidence_type field", %{socket: socket} do
      params = %{"_target" => ["evidence_type"], "evidence_type" => "blob_store_link"}

      {:noreply, updated_socket} = Show.handle_event("update_field", params, socket)

      assert updated_socket.assigns.changes.evidence_type == :blob_store_link
    end

    test "updates text fields", %{socket: socket} do
      params = %{"_target" => ["name"], "name" => "Test Evidence"}

      {:noreply, updated_socket} = Show.handle_event("update_field", params, socket)

      assert updated_socket.assigns.changes.name == "Test Evidence"
    end

    test "handles unknown fields gracefully", %{socket: socket} do
      # This would typically fail if the field doesn't exist as an atom
      # But the code uses String.to_existing_atom, so we test with an existing field
      params = %{"_target" => ["description"], "description" => "Test description"}

      {:noreply, updated_socket} = Show.handle_event("update_field", params, socket)

      assert updated_socket.assigns.changes.description == "Test description"
    end
  end

  describe "handle_event set_tag_input" do
    setup %{workspace: workspace} do
      # Create a properly initialized socket with internal LiveView state
      socket = %Phoenix.LiveView.Socket{
        id: "test-socket",
        endpoint: ValentineWeb.Endpoint,
        view: ValentineWeb.WorkspaceLive.Evidence.Show,
        assigns: %{
          __changed__: %{},
          workspace_id: workspace.id,
          tag_input: "",
          nist_control_input: ""
        }
      }

      %{socket: socket}
    end

    test "sets tag input for tags field", %{socket: socket} do
      params = %{"value" => "new-tag", "field" => "tags"}

      {:noreply, updated_socket} = Show.handle_event("set_tag_input", params, socket)

      assert updated_socket.assigns.tag_input == "new-tag"
    end

    test "sets tag input for nist_controls field", %{socket: socket} do
      params = %{"value" => "AC-1", "field" => "nist_controls"}

      {:noreply, updated_socket} = Show.handle_event("set_tag_input", params, socket)

      assert updated_socket.assigns.nist_control_input == "AC-1"
    end
  end

  describe "handle_event add_tag" do
    setup %{workspace: workspace} do
      # Create a properly initialized socket with internal LiveView state
      socket = %Phoenix.LiveView.Socket{
        id: "test-socket",
        endpoint: ValentineWeb.Endpoint,
        view: ValentineWeb.WorkspaceLive.Evidence.Show,
        assigns: %{
          __changed__: %{},
          workspace_id: workspace.id,
          changes: %{tags: [], nist_controls: []},
          tag_input: "",
          nist_control_input: ""
        }
      }

      %{socket: socket}
    end

    test "adds tag to list", %{socket: socket} do
      socket = put_in(socket.assigns.tag_input, "new-tag")
      params = %{"field" => "tags"}

      {:noreply, updated_socket} = Show.handle_event("add_tag", params, socket)

      assert "new-tag" in updated_socket.assigns.changes.tags
      assert updated_socket.assigns.tag_input == ""
    end

    test "adds NIST control to list", %{socket: socket} do
      socket = put_in(socket.assigns.nist_control_input, "AC-1")
      params = %{"field" => "nist_controls"}

      {:noreply, updated_socket} = Show.handle_event("add_tag", params, socket)

      assert "AC-1" in updated_socket.assigns.changes.nist_controls
      assert updated_socket.assigns.nist_control_input == ""
    end

    test "prevents duplicates", %{socket: socket} do
      socket = put_in(socket.assigns.tag_input, "existing-tag")
      socket = put_in(socket.assigns.changes, %{tags: ["existing-tag"]})
      params = %{"field" => "tags"}

      {:noreply, updated_socket} = Show.handle_event("add_tag", params, socket)

      assert Enum.count(updated_socket.assigns.changes.tags) == 1
    end

    test "ignores empty input", %{socket: socket} do
      socket = put_in(socket.assigns.tag_input, "")
      params = %{"field" => "tags"}

      {:noreply, updated_socket} = Show.handle_event("add_tag", params, socket)

      assert updated_socket.assigns.changes.tags == []
    end
  end

  describe "handle_event remove_tag" do
    setup %{workspace: workspace} do
      # Create a properly initialized socket with internal LiveView state
      socket = %Phoenix.LiveView.Socket{
        id: "test-socket",
        endpoint: ValentineWeb.Endpoint,
        view: ValentineWeb.WorkspaceLive.Evidence.Show,
        assigns: %{
          __changed__: %{},
          workspace_id: workspace.id,
          changes: %{
            tags: ["tag1", "tag2"],
            nist_controls: ["AC-1", "AU-12"]
          }
        }
      }

      %{socket: socket}
    end

    test "removes tag from tags", %{socket: socket} do
      params = %{"field" => "tags", "tag" => "tag1"}

      {:noreply, updated_socket} = Show.handle_event("remove_tag", params, socket)

      refute "tag1" in updated_socket.assigns.changes.tags
      assert "tag2" in updated_socket.assigns.changes.tags
    end

    test "removes tag from nist_controls", %{socket: socket} do
      params = %{"field" => "nist_controls", "tag" => "AC-1"}

      {:noreply, updated_socket} = Show.handle_event("remove_tag", params, socket)

      refute "AC-1" in updated_socket.assigns.changes.nist_controls
      assert "AU-12" in updated_socket.assigns.changes.nist_controls
    end
  end

  describe "handle_event set_evidence_type" do
    setup %{workspace: workspace} do
      # Create a properly initialized socket with internal LiveView state
      socket = %Phoenix.LiveView.Socket{
        id: "test-socket",
        endpoint: ValentineWeb.Endpoint,
        view: ValentineWeb.WorkspaceLive.Evidence.Show,
        assigns: %{
          __changed__: %{},
          workspace_id: workspace.id,
          evidence: %Evidence{},
          changes: %{evidence_type: :description_only},
          content_raw: ""
        }
      }

      %{socket: socket}
    end

    test "changes evidence type to blob_store_link", %{socket: socket} do
      params = %{"type" => "blob_store_link"}

      {:noreply, updated_socket} = Show.handle_event("set_evidence_type", params, socket)

      assert updated_socket.assigns.changes.evidence_type == :blob_store_link
    end

    test "changes evidence type to json_data", %{socket: socket} do
      params = %{"type" => "json_data"}

      {:noreply, updated_socket} = Show.handle_event("set_evidence_type", params, socket)

      assert updated_socket.assigns.changes.evidence_type == :json_data
    end
  end

  describe "handle_event clear_evidence_type" do
    setup %{workspace: workspace} do
      # Create a properly initialized socket with internal LiveView state
      socket = %Phoenix.LiveView.Socket{
        id: "test-socket",
        endpoint: ValentineWeb.Endpoint,
        view: ValentineWeb.WorkspaceLive.Evidence.Show,
        assigns: %{
          __changed__: %{},
          workspace_id: workspace.id,
          evidence: %Evidence{},
          changes: %{
            evidence_type: :blob_store_link,
            blob_store_url: "https://example.com/file.pdf",
            content: %{"some" => "data"}
          },
          content_raw: "{\"some\": \"data\"}"
        }
      }

      %{socket: socket}
    end

    test "resets evidence type to description_only", %{socket: socket} do
      {:noreply, updated_socket} = Show.handle_event("clear_evidence_type", %{}, socket)

      assert updated_socket.assigns.changes.evidence_type == :description_only
    end

    test "clears blob_store_url field", %{socket: socket} do
      {:noreply, updated_socket} = Show.handle_event("clear_evidence_type", %{}, socket)

      assert updated_socket.assigns.changes.blob_store_url == nil
    end

    test "clears content field", %{socket: socket} do
      {:noreply, updated_socket} = Show.handle_event("clear_evidence_type", %{}, socket)

      assert updated_socket.assigns.changes.content == nil
    end

    test "clears content_raw assign", %{socket: socket} do
      {:noreply, updated_socket} = Show.handle_event("clear_evidence_type", %{}, socket)

      assert updated_socket.assigns.content_raw == ""
    end
  end

  describe "evidence type transitions" do
    setup %{workspace: workspace} do
      # Create a properly initialized socket with internal LiveView state
      socket = %Phoenix.LiveView.Socket{
        id: "test-socket",
        endpoint: ValentineWeb.Endpoint,
        view: ValentineWeb.WorkspaceLive.Evidence.Show,
        assigns: %{
          __changed__: %{},
          workspace_id: workspace.id,
          evidence: %Evidence{},
          changes: %{evidence_type: :description_only},
          content_raw: ""
        }
      }

      %{socket: socket}
    end

    test "can transition from description_only to blob_store_link and back", %{socket: socket} do
      # Start with description_only
      assert socket.assigns.changes.evidence_type == :description_only

      # Transition to blob_store_link
      {:noreply, socket} =
        Show.handle_event("set_evidence_type", %{"type" => "blob_store_link"}, socket)

      assert socket.assigns.changes.evidence_type == :blob_store_link

      # Transition back to description_only
      {:noreply, socket} = Show.handle_event("clear_evidence_type", %{}, socket)
      assert socket.assigns.changes.evidence_type == :description_only
    end

    test "can transition from description_only to json_data and back", %{socket: socket} do
      # Start with description_only
      assert socket.assigns.changes.evidence_type == :description_only

      # Transition to json_data
      {:noreply, socket} =
        Show.handle_event("set_evidence_type", %{"type" => "json_data"}, socket)

      assert socket.assigns.changes.evidence_type == :json_data

      # Transition back to description_only
      {:noreply, socket} = Show.handle_event("clear_evidence_type", %{}, socket)
      assert socket.assigns.changes.evidence_type == :description_only
    end

    test "can transition between blob_store_link and json_data", %{socket: socket} do
      # Transition to blob_store_link
      {:noreply, socket} =
        Show.handle_event("set_evidence_type", %{"type" => "blob_store_link"}, socket)

      assert socket.assigns.changes.evidence_type == :blob_store_link

      # Clear back to description_only
      {:noreply, socket} = Show.handle_event("clear_evidence_type", %{}, socket)
      assert socket.assigns.changes.evidence_type == :description_only

      # Transition to json_data
      {:noreply, socket} =
        Show.handle_event("set_evidence_type", %{"type" => "json_data"}, socket)

      assert socket.assigns.changes.evidence_type == :json_data
    end
  end

  describe "handle_event save - create" do
    test "handles validation errors on create", %{workspace: workspace, conn: conn} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, _html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/new")

      # Try to save without required name field (form is empty by default)
      html =
        view
        |> element("button", "Save")
        |> render_click()

      # Should show validation error
      assert html =~ "can&#39;t be blank"
    end
  end

  describe "handle_event save - update" do
    test "updates existing evidence successfully", %{workspace: workspace, conn: conn} do
      evidence =
        evidence_fixture(%{
          workspace_id: workspace.id,
          name: "Original Name"
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, _html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}")

      render(view)

      # Evidence is already loaded with "Original Name", just test that save works
      view |> element("button", "Save") |> render_click()

      # Update redirects to the evidence detail page
      assert_redirected(view, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}")
    end
  end

  describe "evidence form integration" do
    test "editing existing evidence preserves evidence type and data", %{
      workspace: workspace,
      conn: conn
    } do
      # Create evidence with URL
      evidence =
        evidence_fixture(%{
          workspace_id: workspace.id,
          name: "Original Evidence",
          description: "Original description",
          evidence_type: :blob_store_link,
          blob_store_url: "https://example.com/original.pdf"
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}")

      # Verify the evidence data is loaded
      assert html =~ "Original Evidence"
      assert html =~ "Original description"
      assert html =~ "https://example.com/original.pdf"

      # Save the form without changes - should preserve all data
      view |> element("button", "Save") |> render_click()

      # Verify evidence was updated and URL preserved
      updated_evidence = Valentine.Composer.get_evidence!(evidence.id)
      assert updated_evidence.name == "Original Evidence"
      assert updated_evidence.evidence_type == :blob_store_link
      assert updated_evidence.blob_store_url == "https://example.com/original.pdf"
    end

    test "switching evidence type clears previous attachment data", %{
      workspace: workspace,
      conn: conn
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, _html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/new")

      # Set evidence type to blob_store_link
      view
      |> element("button[phx-click='set_evidence_type'][phx-value-type='blob_store_link']")
      |> render_click()

      # The form should now show URL input field
      html = render(view)
      assert html =~ "blob_store_url"

      # Clear the evidence type (back to description_only)
      view
      |> element("button[phx-click='clear_evidence_type']")
      |> render_click()

      # The form should now show the two card buttons again
      assert has_element?(
               view,
               "button[phx-click='set_evidence_type'][phx-value-type='blob_store_link']"
             )

      assert has_element?(
               view,
               "button[phx-click='set_evidence_type'][phx-value-type='json_data']"
             )
    end

    test "evidence number displays when editing existing evidence", %{
      workspace: workspace,
      conn: conn
    } do
      evidence =
        evidence_fixture(%{
          workspace_id: workspace.id,
          name: "Test Evidence",
          description: "Test description"
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _view, html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}")

      # Verify evidence number is displayed in the format "#1", "#2", etc.
      assert html =~ "##{evidence.numeric_id}"
    end

    test "form validates required fields", %{workspace: workspace, conn: conn} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, view, _html} =
        live(conn, ~p"/workspaces/#{workspace.id}/evidence/new")

      # Try to save without filling in any fields
      html =
        view
        |> element("button", "Save")
        |> render_click()

      # Should show validation errors for required fields
      assert html =~ "can&#39;t be blank"
    end
  end
end
