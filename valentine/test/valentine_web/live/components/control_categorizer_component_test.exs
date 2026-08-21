defmodule ValentineWeb.WorkspaceLive.Components.ControlCategorizerComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias Phoenix.LiveView.AsyncResult
  alias ValentineWeb.WorkspaceLive.Components.ControlCategorizerComponent

  defp create_component(_) do
    assumption = assumption_fixture()

    assumption =
      Valentine.Composer.Assumptions.get_assumption!(assumption.id, [:threats, :mitigations])

    mitigation = mitigation_fixture()
    mitigation = Valentine.Composer.Mitigations.get_mitigation!(mitigation.id, [:threats])

    %{
      assumption: assumption,
      mitigation: mitigation,
      assumption_assigns: assigns_for(:assumption, assumption),
      mitigation_assigns: assigns_for(:mitigation, mitigation)
    }
  end

  defp assigns_for(entity_type, entity) do
    %{
      __changed__: %{},
      async_result: AsyncResult.loading(),
      id: "#{entity_type}-control-categorizer-component",
      entity: entity,
      entity_type: entity_type,
      error: nil,
      myself: %Phoenix.LiveComponent.CID{cid: 1},
      patch: "/workspaces/#{entity.workspace_id}/#{entity_type}s",
      request_key: {entity_type, entity.id},
      suggestion: nil,
      usage: nil
    }
  end

  defp external_assigns(assigns) do
    Map.take(assigns, [:id, :entity, :entity_type, :patch])
  end

  defp socket_for(assigns), do: %Phoenix.LiveView.Socket{assigns: assigns}

  describe "render/1" do
    setup [:create_component]

    test "renders entity-specific labels", %{
      assumption_assigns: assumption_assigns,
      mitigation_assigns: mitigation_assigns
    } do
      assumption_html =
        render_component(&ControlCategorizerComponent.render/1, assumption_assigns)

      mitigation_html =
        render_component(&ControlCategorizerComponent.render/1, mitigation_assigns)

      assert assumption_html =~ "Categorize this assumption based on NIST controls"
      assert mitigation_html =~ "Categorize this mitigation based on NIST controls"
    end

    test "renders suggestions, errors, and usage", %{assumption_assigns: assigns} do
      assigns = %{
        assigns
        | async_result: AsyncResult.ok(assigns.async_result, :done),
          error: "An error occurred",
          suggestion: [
            %{"control" => "AC-1", "name" => "Policy", "rational" => "Because"}
          ],
          usage: %{input_tokens: 1_000_000, output_tokens: 1_000_000}
      }

      html = render_component(&ControlCategorizerComponent.render/1, assigns)

      assert html =~ "Assumption"
      assert html =~ "Because"
      assert html =~ "An error occurred"

      assert html =~
               "Mistakes are possible. Review output carefully before use. Current token usage: (In: 1000000, Out: 1000000, Cost: $0.75)"
    end
  end

  describe "mount/1" do
    test "initializes shared async state" do
      socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}

      assert {:ok, socket} = ControlCategorizerComponent.mount(socket)
      assert socket.assigns.async_result.loading
      assert socket.assigns.error == nil
      assert socket.assigns.suggestion == nil
      assert socket.assigns.usage == nil
      assert socket.assigns.request_key == nil
    end
  end

  describe "handle_async/3" do
    setup [:create_component]

    test "stores successful suggestions", %{assumption_assigns: assigns} do
      suggestions = [%{"control" => "AC-1", "name" => "Policy", "rational" => "Because"}]

      assert {:noreply, socket} =
               ControlCategorizerComponent.handle_async(
                 :running_llm,
                 {:ok, {:ok, suggestions}},
                 socket_for(assigns)
               )

      assert socket.assigns.async_result.ok?
      assert socket.assigns.suggestion == suggestions
      assert socket.assigns.error == nil
    end

    test "stores generation errors and stops loading", %{assumption_assigns: assigns} do
      assert {:noreply, socket} =
               ControlCategorizerComponent.handle_async(
                 :running_llm,
                 {:ok, {:error, "gateway unavailable"}},
                 socket_for(assigns)
               )

      refute socket.assigns.async_result.ok?
      assert socket.assigns.async_result.failed == "gateway unavailable"
      assert socket.assigns.error =~ "gateway unavailable"
    end
  end

  describe "handle_event/3" do
    setup [:create_component]

    test "starts a fresh suggestion request", %{assumption_assigns: assigns} do
      assigns = %{
        assigns
        | async_result: AsyncResult.ok(assigns.async_result, :done),
          suggestion: [%{"control" => "AC-1", "name" => "Policy", "rational" => "Because"}]
      }

      assert {:noreply, socket} =
               ControlCategorizerComponent.handle_event(
                 "generate_again",
                 %{},
                 socket_for(assigns)
               )

      assert socket.assigns.async_result.loading
      assert socket.assigns.suggestion == nil
      assert socket.assigns.request_key == {:assumption, assigns.entity.id}
    end

    test "saves selected tags for both entity types", context do
      for {entity_type, entity} <- [
            assumption: context.assumption,
            mitigation: context.mitigation
          ] do
        assigns = assigns_for(entity_type, entity)

        assert {:noreply, socket} =
                 ControlCategorizerComponent.handle_event(
                   "save_tags",
                   %{"controls" => %{"AC-1" => "true", "AC-2" => "false"}},
                   socket_for(assigns)
                 )

        persisted = fetch_entity(entity_type, entity.id)
        assert "AC-1" in persisted.tags
        refute "AC-2" in persisted.tags
        assert socket.redirected == {:live, :patch, %{kind: :push, to: assigns.patch}}
      end
    end
  end

  describe "update/2" do
    setup [:create_component]

    test "starts one request per entity", %{assumption_assigns: assigns} do
      socket = socket_for(%{assigns | request_key: nil})
      external_assigns = external_assigns(assigns)

      assert {:ok, started_socket} =
               ControlCategorizerComponent.update(external_assigns, socket)

      assert started_socket.assigns.async_result.loading
      assert started_socket.assigns.request_key == {:assumption, assigns.entity.id}

      assert {:ok, unchanged_socket} =
               ControlCategorizerComponent.update(external_assigns, started_socket)

      assert unchanged_socket.assigns.request_key == started_socket.assigns.request_key
    end
  end

  defp fetch_entity(:assumption, id), do: Valentine.Composer.Assumptions.get_assumption!(id)
  defp fetch_entity(:mitigation, id), do: Valentine.Composer.Mitigations.get_mitigation!(id)
end
