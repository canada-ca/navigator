defmodule ValentineWeb.WorkspaceLive.FormComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest

  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.FormComponent

  setup do
    workspace = workspace_fixture()

    assigns = %{__changed__: %{}, workspace: workspace, id: "form-component"}

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    test "renders the form with an Edit title if workspace exists", %{assigns: assigns} do
      html = render_component(FormComponent, assigns)
      assert html =~ "Edit Workspace"
    end

    test "renders the form with a New title if workspace does not exists", %{assigns: assigns} do
      assigns = %{
        assigns
        | workspace: %Valentine.Composer.Workspace{}
      }

      html = render_component(FormComponent, assigns)
      assert html =~ "New Workspace"
    end
  end

  describe "handle_event/3" do
    test "validates the form invalid if fields are missing", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          workspace: %Valentine.Composer.Workspace{}
        })

      {:noreply, socket} =
        FormComponent.handle_event("validate", %{"workspace" => %{}}, socket)

      assert socket.assigns.changeset.valid? == false
    end

    test "validates the form valid if nothing is missing", %{socket: socket} do
      {:noreply, socket} =
        FormComponent.handle_event("validate", %{"workspace" => %{}}, socket)

      assert socket.assigns.changeset.valid? == true
    end

    test "updates an existing workspace if the owner is editing", %{socket: socket} do
      workspace = workspace_fixture()

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :edit,
          workspace: workspace,
          current_user: workspace.owner,
          flash: %{},
          patch: "/workspaces"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{"workspace" => %{content: "some updated content"}},
          socket
        )

      assert socket.assigns.flash["info"] == "Workspace updated successfully"
      assert socket.assigns.patch == socket.assigns.patch
    end

    test "does not update an existing workspace if the owner is not editing", %{socket: socket} do
      workspace = workspace_fixture()

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :edit,
          workspace: workspace,
          current_user: "some user",
          flash: %{},
          patch: "/workspaces"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{"workspace" => %{content: "some updated content"}},
          socket
        )

      assert socket.assigns.flash["error"] == "You are not the owner of this workspace"
    end

    test "returns a changeset for an existing workspace", %{socket: socket} do
      workspace = workspace_fixture()

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :edit,
          workspace: workspace,
          current_user: workspace.owner,
          flash: %{},
          patch: "/workspaces"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{"workspace" => %{name: nil}},
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end

    test "saves a new workspace", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          current_user: "some user",
          workspace: %Valentine.Composer.Workspace{},
          flash: %{},
          patch: "/workspace/s"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{
            "workspace" => %{
              "name" => "some name"
            }
          },
          socket
        )

      assert socket.assigns.flash["info"] == "Workspace created successfully"
      assert socket.assigns.patch == socket.assigns.patch
    end

    test "returns a changeset for a new workspace", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          workspace: %Valentine.Composer.Workspace{},
          flash: %{},
          current_user: "some user",
          patch: "/workspaces"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{
            "workspace" => %{
              "name" => nil
            }
          },
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end
  end
end
