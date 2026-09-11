defmodule ValentineWeb.WorkspaceLive.Components.QuillComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Components.QuillComponent

  test "renders properly with id=\"quill-editor\"" do
    html =
      render_component(QuillComponent, %{
        content: "Hello, World!",
        editable: true,
        workspace_id: "workspace-id",
        current_user: "owner"
      })

    assert html =~ "id=\"quill-editor\""
    assert html =~ "Hello, World!"
    assert html =~ "data-read-only=\"false\""
  end

  describe "handle_event/2" do
    test "quill-change" do
      workspace = workspace_fixture()
      socket = component_socket(workspace, workspace.owner)

      {:noreply, ^socket} =
        QuillComponent.handle_event("quill-change", %{"delta" => "delta"}, socket)

      assert_received {:quill_change, "delta"}
    end

    test "quill-save" do
      workspace = workspace_fixture()
      socket = component_socket(workspace, workspace.owner)

      {:noreply, ^socket} =
        QuillComponent.handle_event("quill-save", %{"content" => "content"}, socket)

      assert_received {:quill_save, "content"}
    end

    test "reader events are inert" do
      workspace =
        workspace_fixture(%{permissions: %{"reader@localhost" => "read"}})

      socket = component_socket(workspace, "reader@localhost")

      assert {:noreply, _socket} =
               QuillComponent.handle_event("quill-change", %{"delta" => "delta"}, socket)

      assert {:noreply, _socket} =
               QuillComponent.handle_event("quill-save", %{"content" => "content"}, socket)

      refute_received {:quill_change, _delta}
      refute_received {:quill_save, _content}
    end
  end

  defp component_socket(workspace, identity) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        workspace_id: workspace.id,
        current_user: identity
      }
    }
  end
end
