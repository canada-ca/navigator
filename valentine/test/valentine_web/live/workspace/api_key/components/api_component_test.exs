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
      refute html =~ "api_key[workspace_id]"
      refute html =~ "api_key[owner]"
      refute html =~ "api_key[status]"
    end
  end

  describe "handle_event/3" do
    setup [:create_api_key]

    test "validates the form invalid if fields are missing", %{socket: socket} do
      {:noreply, socket} =
        ApiKeyComponent.handle_event(
          "validate",
          %{"api_key" => %{"label" => nil}},
          socket
        )

      assert socket.assigns.changeset.valid? == false
    end

    test "validates the form valid if nothing is missing", %{socket: socket} do
      {:noreply, socket} =
        ApiKeyComponent.handle_event(
          "validate",
          %{"api_key" => %{"label" => "some label"}},
          socket
        )

      assert socket.assigns.changeset.valid? == true
    end

    test "saves a new api_key using trusted protected fields", %{socket: socket} do
      workspace = workspace_fixture()
      other_workspace = workspace_fixture(%{owner: "other.owner@localhost"})

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          api_key: %Valentine.Composer.ApiKey{
            workspace_id: workspace.id
          },
          current_user: workspace.owner,
          flash: %{},
          patch: "/workspace/00000000-0000-0000-0000-000000000000/api_keys",
          workspace: workspace
        })

      {:noreply, socket} =
        ApiKeyComponent.handle_event(
          "save",
          %{
            "api_key" => %{
              label: "some label",
              owner: other_workspace.owner,
              status: "revoked",
              workspace_id: other_workspace.id
            }
          },
          socket
        )

      assert socket.assigns.flash["info"] == "API Key created successfully"
      assert socket.assigns.patch == socket.assigns.patch

      api_key =
        workspace.id
        |> Valentine.Composer.ApiKeys.list_api_keys_by_workspace()
        |> Enum.find(&(&1.label == "some label"))

      assert api_key.owner == workspace.owner
      assert api_key.status == :active
      assert api_key.workspace_id == workspace.id
      assert Valentine.Composer.ApiKeys.list_api_keys_by_workspace(other_workspace.id) == []
    end

    test "returns a changeset for a new api_key", %{socket: socket} do
      workspace = socket.assigns.workspace

      socket =
        Map.put(socket, :assigns, %{
          __changed__: %{},
          action: :new,
          api_key: %Valentine.Composer.ApiKey{
            workspace_id: "00000000-0000-0000-0000-000000000000"
          },
          current_user: workspace.owner,
          flash: %{},
          patch: "/workspace/00000000-0000-0000-0000-000000000000/api_keys",
          workspace: workspace
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

    test "rejects API key creation by a non-owner", %{socket: socket} do
      workspace = socket.assigns.workspace

      socket =
        Map.put(
          socket,
          :assigns,
          Map.merge(socket.assigns, %{
            current_user: "collaborator@localhost",
            flash: %{}
          })
        )

      {:noreply, socket} =
        ApiKeyComponent.handle_event(
          "save",
          %{"api_key" => %{"label" => "Unauthorized key"}},
          socket
        )

      assert socket.assigns.flash["error"] ==
               "Only workspace owners can generate API keys"

      assert Valentine.Composer.ApiKeys.list_api_keys_by_workspace(workspace.id)
             |> Enum.all?(&(&1.label != "Unauthorized key"))
    end
  end
end
