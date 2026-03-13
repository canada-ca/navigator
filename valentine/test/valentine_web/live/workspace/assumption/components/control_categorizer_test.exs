defmodule ValentineWeb.WorkspaceLive.Assumption.Components.ControlCategorizerTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.Assumption.Components.ControlCategorizer

  defp create_component(_) do
    assumption = assumption_fixture()
    assumption = Valentine.Composer.get_assumption!(assumption.id, [:threats, :mitigations])

    assigns = %{
      __changed__: %{},
      async_result: Phoenix.LiveView.AsyncResult.loading(),
      id: "assumption-control-categorizer-component",
      error: nil,
      assumption: assumption,
      patch: ~p"/workspaces/#{assumption.workspace_id}/assumptions",
      suggestion: nil,
      usage: nil,
      workspace_id: assumption.workspace_id
    }

    socket = %Phoenix.LiveView.Socket{assigns: assigns}

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_component]

    test "displays a spinner on load", %{assigns: assigns} do
      html = render_component(ControlCategorizer, assigns)
      assert html =~ "anim-rotate"
    end

    test "displays a list of control suggestions when set", %{assigns: assigns} do
      assigns =
        Map.put(assigns, :suggestion, [
          %{
            "control" => "control",
            "name" => "name",
            "rational" => "rational"
          }
        ])

      html = render_component(ControlCategorizer, assigns)
      assert html =~ "rational"
    end

    test "displays an error message when error is present", %{assigns: assigns} do
      assigns = Map.put(assigns, :error, "An error occurred")
      html = render_component(ControlCategorizer, assigns)
      assert html =~ "An error occurred"
    end

    test "displays a usage warning", %{assigns: assigns} do
      assigns =
        Map.put(assigns, :usage, %{input_tokens: 1_000_000, output_tokens: 1_000_000})

      html = render_component(ControlCategorizer, assigns)

      assert html =~
               "Mistakes are possible. Review output carefully before use. Current token usage: (In: 1000000, Out: 1000000, Cost: $0.75)"
    end
  end

  describe "mount/1" do
    setup [:create_component]

    test "properly assigns all the right values", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %{}))
      {:ok, updated_socket} = ControlCategorizer.mount(socket)
      assert updated_socket.assigns.error == nil
      assert updated_socket.assigns.suggestion == nil
      assert updated_socket.assigns.usage == nil
      assert updated_socket.assigns.async_result.loading == true
    end
  end

  describe "handle_async/3" do
    setup [:create_component]

    test "updates the socket with the async_result", %{socket: socket} do
      {:noreply, updated_socket} =
        ControlCategorizer.handle_async(:running_llm, {:ok, "some_result"}, socket)

      assert updated_socket.assigns.async_result.ok? == true
      assert updated_socket.assigns.async_result.result == "some_result"

      {:noreply, updated_socket} =
        ControlCategorizer.handle_async(:running_llm, {:error, "some_error"}, socket)

      assert updated_socket.assigns.async_result.ok? == false
      assert updated_socket.assigns.async_result.failed == "some_error"
    end
  end

  describe "handle_event/3" do
    setup [:create_component]

    test "generate_again resets the assigns", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :suggestion, %{}))

      socket =
        Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %Phoenix.LiveComponent.CID{}))

      {:noreply, updated_socket} =
        ControlCategorizer.handle_event("generate_again", %{}, socket)

      assert updated_socket.assigns.suggestion == nil
    end

    test "saves tags to an assumption", %{socket: socket} do
      {:noreply, updated_socket} =
        ControlCategorizer.handle_event(
          "save_tags",
          %{"controls" => %{"AC-1" => "true", "AC-2" => "false"}},
          socket
        )

      updated_assumption = Valentine.Composer.get_assumption!(socket.assigns.assumption.id)

      assert "AC-1" in updated_assumption.tags
      refute "AC-2" in updated_assumption.tags

      assert updated_socket.redirected ==
               {:live, :patch, %{kind: :push, to: socket.assigns.patch}}
    end
  end

  describe "update/2" do
    setup [:create_component]

    test "updates the socket with the chat_complete data", %{socket: socket} do
      data = %{
        content:
          Jason.encode!(%{
            "controls" => [
              %{
                "control" => "control",
                "name" => "name",
                "rational" => "rational"
              }
            ]
          })
      }

      {:ok, updated_socket} =
        ControlCategorizer.update(%{chat_complete: data}, socket)

      assert updated_socket.assigns.suggestion == [
               %{
                 "control" => "control",
                 "name" => "name",
                 "rational" => "rational"
               }
             ]
    end

    test "normalizes a single control object and atom keys", %{socket: socket} do
      data = %{
        content:
          Jason.encode!(%{
            "controls" => %{
              control: "AC-1",
              name: "Access Control Policy",
              rational: "This assumption depends on access control governance"
            }
          })
      }

      {:ok, updated_socket} =
        ControlCategorizer.update(%{chat_complete: data}, socket)

      assert updated_socket.assigns.suggestion == [
               %{
                 "control" => "AC-1",
                 "name" => "Access Control Policy",
                 "rational" => "This assumption depends on access control governance"
               }
             ]
    end

    test "returns an error if the chat_complete data is not valid JSON", %{socket: socket} do
      {:ok, updated_socket} =
        ControlCategorizer.update(%{chat_complete: %{content: "invalid_json"}}, socket)

      assert updated_socket.assigns.error == "Error decoding response"
    end

    test "updates the socket with the usage_update data", %{socket: socket} do
      usage = %{input_tokens: 0, output_tokens: 0}

      {:ok, updated_socket} =
        ControlCategorizer.update(%{usage_update: usage}, socket)

      assert updated_socket.assigns.usage == usage
    end

    test "kicks off a new LLM chain run once it is updated", %{assigns: assigns, socket: socket} do
      socket =
        Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %Phoenix.LiveComponent.CID{}))

      {:ok, updated_socket} =
        ControlCategorizer.update(assigns, socket)

      assert updated_socket.assigns.async_result.loading == true
    end
  end
end
