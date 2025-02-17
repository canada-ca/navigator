defmodule ValentineWeb.WorkspaceLive.Collaboration.IndexTest do
  use ValentineWeb.ConnCase

  import Valentine.ComposerFixtures

  setup do
    user = user_fixture()
    workspace = workspace_fixture(%{owner: user.email})
    some_user = user_fixture(%{email: "some.other.user@localhost"})

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        touched: false,
        live_action: nil,
        flash: %{},
        workspace_id: workspace.id
      }
    }

    %{
      socket: socket,
      workspace_id: workspace.id,
      user: user,
      some_user: some_user
    }
  end

  describe "mount/3" do
    test "mounts the component and assigns the correct assigns", %{
      workspace_id: workspace_id,
      socket: socket
    } do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.Collaboration.Index.mount(
          %{"workspace_id" => workspace_id},
          nil,
          socket
        )

      assert socket.assigns.workspace_id == workspace_id
      assert length(socket.assigns.users) == 2
    end
  end

  describe "handle_params/3 assigns the page title to :index action" do
    test "assigns the page title to 'Collaboration' when live_action is :index" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          live_action: :index,
          flash: %{},
          workspace_id: 1
        }
      }

      {:noreply, socket} =
        ValentineWeb.WorkspaceLive.Collaboration.Index.handle_params(nil, nil, socket)

      assert socket.assigns.page_title == "Collaboration"
    end
  end
end
