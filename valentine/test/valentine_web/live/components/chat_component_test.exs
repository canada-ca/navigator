defmodule ValentineWeb.WorkspaceLive.Components.ChatComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Components.ChatComponent

  defp create_component(_) do
    workspace = workspace_fixture()

    assigns = %{
      __changed__: %{},
      active_module: "some_active_module",
      active_action: "some_active_action",
      async_result: Phoenix.LiveView.AsyncResult.loading(),
      messages: [],
      delta: nil,
      id: "chat-component",
      workspace_id: workspace.id,
      current_user: "test_user@example.com"
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_component]

    test "displays a blank slate if no messages exist", %{assigns: assigns} do
      html = render_component(ChatComponent, assigns)
      assert html =~ "Ask AI Assistant"
    end

    test "displas a message if messages exist", %{assigns: assigns} do
      assigns =
        assigns
        |> Map.put(:messages, [%{role: :user, content: "Hello, world!"}])
        |> Map.put(:delta, nil)

      html = render_component(ChatComponent, assigns)
      assert html =~ "Hello, world!"
    end

    test "displays a message delta if it exists", %{assigns: assigns} do
      assigns =
        assigns
        |> Map.put(:delta, "{\"content\":\"I am a system")
        |> Map.put(:messages, [%{role: :user, content: "Hello, world!"}])

      html = render_component(ChatComponent, assigns)
      assert html =~ "I am a system"
    end

    test "displays a chat input container", %{assigns: assigns} do
      html = render_component(ChatComponent, assigns)
      assert html =~ "Ask AI Assistant"
    end
  end

  describe "mount/1" do
    setup [:create_component]

    test "properly assigns all the right values", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %{}))
      {:ok, updated_socket} = ChatComponent.mount(socket)
      assert updated_socket.assigns.messages == []
      assert updated_socket.assigns.delta == nil
      assert updated_socket.assigns.usage == nil
      assert updated_socket.assigns.async_result.loading == true
    end
  end

  describe "update/2" do
    setup [:create_component]

    test "updates the socket with the chat_complete data", %{socket: socket} do
      data = %{content: "Assistant reply"}

      {:ok, updated_socket} = ChatComponent.update(%{chat_complete: data}, socket)
      assert List.last(updated_socket.assigns.messages).content == data.content
    end

    test "renders assistant text content", %{assigns: assigns} do
      assigns = Map.put(assigns, :messages, [%{role: :assistant, content: "Rendered reply"}])

      html = render_component(ChatComponent, assigns)
      assert html =~ "Rendered reply"
    end

    test "updates the socket with the chat_response delta data", %{socket: socket} do
      chunk = "{\"content\":\"I am a system"

      {:ok, updated_socket} = ChatComponent.update(%{chat_response: chunk}, socket)
      assert updated_socket.assigns.delta == chunk
    end

    test "updates the socket with the skill_result data", %{socket: socket} do
      data = %{
        id: "some_id",
        status: "some_status",
        msg: "some_msg"
      }

      {:ok, updated_socket} = ChatComponent.update(%{skill_result: data}, socket)

      assert hd(updated_socket.assigns.messages).content ==
               "The user clicked the button with id: some_id and the result was: some_status - some_msg"
    end

    test "updates the socket with the usage_update data", %{socket: socket} do
      usage = %{input_tokens: 0, output_tokens: 0}
      {:ok, updated_socket} = ChatComponent.update(%{usage_update: usage}, socket)
      assert updated_socket.assigns.usage == usage
    end

    test "updates the socket with any assigns", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %{}))

      assigns = %{
        active_module: "some_active_module",
        active_action: "some_active_action",
        workspace_id: socket.assigns.workspace_id,
        current_user: socket.assigns.current_user,
        some_key: "some_value"
      }

      {:ok, updated_socket} = ChatComponent.update(assigns, socket)
      assert updated_socket.assigns.some_key == "some_value"
    end
  end

  describe "handle_async/3" do
    setup [:create_component]

    test "updates the socket with the async_result", %{socket: socket} do
      async_fun_result = {:ok, "some_result"}

      {:noreply, updated_socket} =
        ChatComponent.handle_async(:running_llm, async_fun_result, socket)

      assert updated_socket.assigns.async_result.ok? == true
      assert updated_socket.assigns.async_result.result == "some_result"

      async_fun_result = {:error, "some_error"}

      {:noreply, updated_socket} =
        ChatComponent.handle_async(:running_llm, async_fun_result, socket)

      assert updated_socket.assigns.async_result.ok? == false
      assert updated_socket.assigns.async_result.failed == "some_error"
    end
  end

  describe "handle_event/3" do
    setup [:create_component]

    test "clears the existing messages from the llm chain if the value is /clear",
         %{socket: socket} do
      value = "/clear"

      socket =
        Map.put(
          socket,
          :assigns,
          Map.put(socket.assigns, :messages, [
            %{role: :system, content: "I am a system"},
            %{role: :user, content: "Hello, world!"}
          ])
        )

      socket =
        Map.put(
          socket,
          :assigns,
          Map.put(socket.assigns, :myself, "myself")
        )

      {:noreply, updated_socket} =
        ChatComponent.handle_event("chat_submit", %{"value" => value}, socket)

      assert length(updated_socket.assigns.messages) == 0
    end

    test "adds a new system and user message to the llm chain", %{socket: socket} do
      value = "Hello, world!"

      socket =
        Map.put(
          socket,
          :assigns,
          Map.put(socket.assigns, :myself, "myself")
        )

      {:noreply, updated_socket} =
        ChatComponent.handle_event("chat_submit", %{"value" => value}, socket)

      assert length(updated_socket.assigns.messages) == 2
      assert hd(updated_socket.assigns.messages).role == :system
      assert hd(tl(updated_socket.assigns.messages)).role == :user
      assert hd(tl(updated_socket.assigns.messages)).content == value
    end

    test "reuses a single system message across submits", %{socket: socket} do
      socket =
        Map.put(
          socket,
          :assigns,
          socket.assigns
          |> Map.put(:myself, "myself")
          |> Map.put(:messages, [
            %{role: :system, content: "old system prompt"},
            %{role: :assistant, content: "prior answer"}
          ])
        )

      {:noreply, updated_socket} =
        ChatComponent.handle_event("chat_submit", %{"value" => "Hello again"}, socket)

      system_messages = Enum.filter(updated_socket.assigns.messages, &(&1.role == :system))

      assert length(system_messages) == 1
      assert Enum.at(updated_socket.assigns.messages, 1).role == :assistant
      assert List.last(updated_socket.assigns.messages).role == :user
      assert List.last(updated_socket.assigns.messages).content == "Hello again"
    end
  end

  describe "run_chain/1" do
    setup [:create_component]

    test "runs the chain", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %{}))
      updated_socket = ChatComponent.run_chain(socket)
      assert updated_socket.assigns.async_result != nil
    end
  end
end
