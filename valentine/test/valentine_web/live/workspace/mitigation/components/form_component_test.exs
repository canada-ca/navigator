defmodule ValentineWeb.WorkspaceLive.Mitigation.Components.FormComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest

  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Mitigation.Components.FormComponent

  defp create_mitigation(_) do
    workspace = workspace_fixture()
    mitigation = mitigation_fixture(%{workspace_id: workspace.id})

    assigns = %{
      __changed__: %{},
      current_user: workspace.owner,
      mitigation: mitigation,
      on_cancel: "/workspace/00000000-0000-0000-0000-000000000000/mitigations",
      id: "form-component"
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_mitigation]

    test "renders the form with an Edit title if mitigation exists", %{assigns: assigns} do
      html = render_component(FormComponent, assigns)
      assert html =~ "Edit Mitigation"
    end

    test "renders the form with a New title if mitigation exists", %{assigns: assigns} do
      assigns = %{
        assigns
        | mitigation: %Valentine.Composer.Mitigation{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          }
      }

      html = render_component(FormComponent, assigns)
      assert html =~ "New Mitigation"
    end
  end

  describe "handle_event/3" do
    setup [:create_mitigation]

    test "validates the form invalid if fields are missing", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          mitigation: %Valentine.Composer.Mitigation{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          }
        })

      {:noreply, socket} =
        FormComponent.handle_event("validate", %{"mitigation" => %{}}, socket)

      assert socket.assigns.changeset.valid? == false
    end

    test "validates the form valid if nothing is missing", %{socket: socket} do
      {:noreply, socket} =
        FormComponent.handle_event("validate", %{"mitigation" => %{}}, socket)

      assert socket.assigns.changeset.valid? == true
    end

    test "updates an existing mitigation", %{assigns: assigns, socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :edit,
          mitigation: mitigation_fixture(),
          current_user: assigns.current_user,
          flash: %{},
          on_cancel: "/workspace/00000000-0000-0000-0000-000000000000/mitigations",
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/mitigation/00000000-0000-0000-0000-000000000000"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{"mitigation" => %{content: "some updated content"}},
          socket
        )

      assert socket.assigns.flash["info"] == "Mitigation updated successfully"
      assert socket.assigns.patch == socket.assigns.patch
    end

    test "returns a changeset for an existing mitigation", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :edit,
          mitigation: mitigation_fixture(),
          flash: %{},
          on_cancel: "/workspace/00000000-0000-0000-0000-000000000000/mitigations",
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/mitigation/00000000-0000-0000-0000-000000000000"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{"mitigation" => %{content: nil}},
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end

    test "saves a new mitigation", %{assigns: assigns, socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          mitigation: %Valentine.Composer.Mitigation{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          },
          current_user: assigns.current_user,
          flash: %{},
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/mitigation/00000000-0000-0000-0000-000000000000"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{
            "mitigation" => %{
              content: "some content",
              workspace_id: assigns.mitigation.workspace_id
            }
          },
          socket
        )

      assert socket.assigns.flash["info"] == "Mitigation created successfully"
      assert socket.assigns.patch == socket.assigns.patch
    end

    test "returns a changeset for a new mitigation", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          mitigation: %Valentine.Composer.Mitigation{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          },
          flash: %{},
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/mitigation/00000000-0000-0000-0000-000000000000"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{
            "mitigation" => %{
              content: nil
            }
          },
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end
  end
end
