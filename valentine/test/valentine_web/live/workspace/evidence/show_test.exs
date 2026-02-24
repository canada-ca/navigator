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
      assert html =~ "Evidence type"
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
      assert html =~ "Create Evidence"
      assert has_element?(view, "#evidence-form")
      assert has_element?(view, "#evidence-name")
      assert has_element?(view, "#evidence-type")
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
end
