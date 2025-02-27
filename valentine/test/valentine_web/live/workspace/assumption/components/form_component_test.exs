defmodule ValentineWeb.WorkspaceLive.Assumption.Components.FormComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest

  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Assumption.Components.FormComponent

  defp create_assumption(_) do
    workspace = workspace_fixture()
    assumption = assumption_fixture(%{workspace_id: workspace.id})

    assigns = %{
      __changed__: %{},
      assumption: assumption,
      current_user: workspace.owner,
      on_cancel: "/workspace/00000000-0000-0000-0000-000000000000/assumptions",
      id: "form-component"
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_assumption]

    test "renders the form with an Edit title if assumption exists", %{assigns: assigns} do
      html = render_component(FormComponent, assigns)
      assert html =~ "Edit Assumption"
    end

    test "renders the form with a New title if assumption exists", %{assigns: assigns} do
      assigns = %{
        assigns
        | assumption: %Valentine.Composer.Assumption{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          }
      }

      html = render_component(FormComponent, assigns)
      assert html =~ "New Assumption"
    end
  end

  describe "handle_event/3" do
    setup [:create_assumption]

    test "validates the form invalid if fields are missing", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          assumption: %Valentine.Composer.Assumption{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          }
        })

      {:noreply, socket} =
        FormComponent.handle_event("validate", %{"assumption" => %{}}, socket)

      assert socket.assigns.changeset.valid? == false
    end

    test "validates the form valid if nothing is missing", %{socket: socket} do
      {:noreply, socket} =
        FormComponent.handle_event("validate", %{"assumption" => %{}}, socket)

      assert socket.assigns.changeset.valid? == true
    end

    test "updates an existing assumption", %{socket: socket} do
      workspace = workspace_fixture()
      assumption = assumption_fixture(%{workspace_id: workspace.id})

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :edit,
          assumption: assumption,
          current_user: workspace.owner,
          flash: %{},
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/assumption/00000000-0000-0000-0000-000000000000",
          on_canel: "/workspace/00000000-0000-0000-0000-000000000000/assumptions"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{"assumption" => %{content: "some updated content"}},
          socket
        )

      assert socket.assigns.flash["info"] == "Assumption updated successfully"
      assert socket.assigns.patch == socket.assigns.patch
    end

    test "returns a changeset for an existing assumption", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :edit,
          assumption: assumption_fixture(),
          flash: %{},
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/assumption/00000000-0000-0000-0000-000000000000",
          on_canel: "/workspace/00000000-0000-0000-0000-000000000000/assumptions"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{"assumption" => %{content: nil}},
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end

    test "saves a new assumption", %{assigns: assigns, socket: socket} do
      workspace = workspace_fixture()

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          assumption: %Valentine.Composer.Assumption{
            workspace_id: workspace.id
          },
          current_user: workspace.owner,
          flash: %{},
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/assumption/00000000-0000-0000-0000-000000000000"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{
            "assumption" => %{
              content: "some content",
              workspace_id: assigns.assumption.workspace_id
            }
          },
          socket
        )

      assert socket.assigns.flash["info"] == "Assumption created successfully"
      assert socket.assigns.patch == socket.assigns.patch
    end

    test "returns a changeset for a new assumption", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          assumption: %Valentine.Composer.Assumption{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          },
          flash: %{},
          patch:
            "/workspace/00000000-0000-0000-0000-000000000000/assumption/00000000-0000-0000-0000-000000000000"
        })

      {:noreply, socket} =
        FormComponent.handle_event(
          "save",
          %{
            "assumption" => %{
              content: nil
            }
          },
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end
  end
end
