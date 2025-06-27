defmodule ValentineWeb.WorkspaceLive.ApiKey.Components.ApiKeyComponentTest do
  use ValentineWeb.ConnCase
  import Phoenix.LiveViewTest

  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.ApiKey.Components.ApiKeyComponent

  defp create_api_key(_) do
    workspace = workspace_fixture()
    api_key = api_key_fixture(%{workspace_id: workspace.id})

    assigns = %{
      __changed__: %{},
      api_key: api_key,
      current_user: workspace.owner,
      patch: "/workspace/00000000-0000-0000-0000-000000000000/api_keys",
      id: :generate,
      workspace: workspace
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_api_key]

    test "renders the form with a New title if api_key exists", %{assigns: assigns} do
      assigns = %{
        assigns
        | api_key: %Valentine.Composer.ApiKey{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          }
      }

      html = render_component(ApiKeyComponent, assigns)
      assert html =~ "Generate API Key"
    end
  end

  describe "handle_event/3" do
    setup [:create_api_key]

    test "validates the form invalid if fields are missing", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          api_key: %Valentine.Composer.ApiKey{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          }
        })

      {:noreply, socket} =
        ApiKeyComponent.handle_event("validate", %{"api_key" => %{}}, socket)

      assert socket.assigns.changeset.valid? == false
    end

    test "validates the form valid if nothing is missing", %{socket: socket} do
      {:noreply, socket} =
        ApiKeyComponent.handle_event("validate", %{"api_key" => %{}}, socket)

      assert socket.assigns.changeset.valid? == true
    end

    test "saves a new api_key", %{assigns: assigns, socket: socket} do
      workspace = workspace_fixture()

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          api_key: %Valentine.Composer.ApiKey{
            workspace_id: workspace.id
          },
          current_user: workspace.owner,
          flash: %{},
          patch: "/workspace/00000000-0000-0000-0000-000000000000/api_keys"
        })

      {:noreply, socket} =
        ApiKeyComponent.handle_event(
          "save",
          %{
            "api_key" => %{
              label: "some label",
              owner: assigns.current_user,
              status: "active",
              workspace_id: assigns.api_key.workspace_id
            }
          },
          socket
        )

      assert socket.assigns.flash["info"] == "API Key created successfully"
      assert socket.assigns.patch == socket.assigns.patch
    end

    test "returns a changeset for a new api_key", %{socket: socket} do
      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          api_key: %Valentine.Composer.ApiKey{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          },
          flash: %{},
          patch: "/workspace/00000000-0000-0000-0000-000000000000/api_keys"
        })

      {:noreply, socket} =
        ApiKeyComponent.handle_event(
          "save",
          %{
            "api_key" => %{
              label: nil
            }
          },
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end
  end
end
