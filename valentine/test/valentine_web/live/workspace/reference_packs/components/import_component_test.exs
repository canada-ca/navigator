defmodule ValentineWeb.WorkspaceLive.ReferencePacks.Components.ImportComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mock

  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.ReferencePacks.Components.ImportComponent

  setup do
    workspace = workspace_fixture()

    assigns = %{
      __changed__: %{},
      flash: %{},
      workspace: workspace,
      current_user: workspace.owner,
      patch: "/workspaces/#{workspace.id}/reference_packs",
      id: "import-component"
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    test "renders the form with an Import reference pack title", %{assigns: assigns} do
      assigns =
        %{
          assigns
          | workspace: %Valentine.Composer.Workspace{}
        }
        |> Map.delete(:flash)

      html = render_component(ImportComponent, assigns)
      assert html =~ "Import reference pack"
    end
  end

  describe "update/2" do
    test "sets upload assigns" do
      {:ok, socket} = ImportComponent.update(%{}, %Phoenix.LiveView.Socket{})

      assert socket.assigns.upload_errors == []
      assert socket.assigns.uploaded_file == nil
      assert socket.assigns.uploads != nil
    end
  end

  describe "handle_event/3" do
    test "validate does nothing", %{socket: socket} do
      {:noreply, updated_socket} =
        ImportComponent.handle_event("validate", %{"workspace" => %{}}, socket)

      assert socket == updated_socket
    end

    test "save returns a flash info if the file is uploaded", %{socket: socket} do
      with_mock Phoenix.LiveView, [:passthrough],
        consume_uploaded_entries: fn _socket, :import, _fn -> [{:ok, nil}] end do
        {:noreply, updated_socket} =
          ImportComponent.handle_event("save", %{"workspace" => %{}}, socket)

        assert updated_socket.assigns.flash["info"] == "Reference pack imported successfully"

        assert updated_socket.assigns.patch ==
                 "/workspaces/#{socket.assigns.workspace.id}/reference_packs"
      end
    end

    test "save returns an error if the file is not uploaded", %{socket: socket} do
      with_mock Phoenix.LiveView, [:passthrough],
        consume_uploaded_entries: fn _socket, :import, _fn -> [{:error, "Invalid file"}] end do
        {:noreply, updated_socket} =
          ImportComponent.handle_event("save", %{"workspace" => %{}}, socket)

        assert updated_socket.assigns.upload_errors == ["Invalid file"]
      end
    end
  end
end
