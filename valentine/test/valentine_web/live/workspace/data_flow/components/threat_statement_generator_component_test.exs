defmodule ValentineWeb.WorkspaceLive.DataFlow.Components.ThreatStatementGeneratorComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias ValentineWeb.WorkspaceLive.DataFlow.Components.ThreatStatementGeneratorComponent

  defp create_component(_) do
    dfd = data_flow_diagram_fixture()
    node = Valentine.Composer.DataFlowDiagram.add_node(dfd.workspace_id, %{"type" => "test"})

    assigns = %{
      __changed__: %{},
      async_result: Phoenix.LiveView.AsyncResult.loading(),
      id: "threat-statement-generator-component",
      element_id: node["data"]["id"],
      error: nil,
      threat: nil,
      usage: nil,
      workspace_id: dfd.workspace_id
    }

    socket = %Phoenix.LiveView.Socket{
      assigns: assigns
    }

    %{assigns: assigns, socket: socket}
  end

  describe "render/1" do
    setup [:create_component]

    test "displays a spinner on load", %{assigns: assigns} do
      html = render_component(ThreatStatementGeneratorComponent, assigns)
      assert html =~ "anim-rotate"
    end

    test "displays a threat statement when threat is present", %{assigns: assigns} do
      assigns = Map.put(assigns, :threat, threat_fixture())
      html = render_component(ThreatStatementGeneratorComponent, assigns)
      assert html =~ Valentine.Composer.Threat.show_statement(assigns.threat)
      {:safe, banner} = Valentine.Composer.Threat.stride_banner(assigns.threat)
      assert html =~ banner
    end

    test "displays an error message when error is present", %{assigns: assigns} do
      assigns = Map.put(assigns, :error, "An error occurred")
      html = render_component(ThreatStatementGeneratorComponent, assigns)
      assert html =~ "An error occurred"
    end

    test "displays a usage warning", %{assigns: assigns} do
      assigns =
        Map.put(assigns, :usage, %{input_tokens: 1_000_000, output_tokens: 1_000_000})

      html = render_component(ThreatStatementGeneratorComponent, assigns)

      assert html =~
               "Mistakes are possible. Review output carefully before use. Current token usage: (In: 1000000, Out: 1000000, Cost: $0.75)"
    end
  end

  describe "mount/1" do
    setup [:create_component]

    test "properly assigns all the right values", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %{}))
      {:ok, updated_socket} = ThreatStatementGeneratorComponent.mount(socket)
      assert updated_socket.assigns.error == nil
      assert updated_socket.assigns.threat == nil
      assert updated_socket.assigns.usage == nil
      assert updated_socket.assigns.async_result.loading == true
    end
  end

  describe "handle_async/3" do
    setup [:create_component]

    test "updates the socket with the async_result", %{socket: socket} do
      async_fun_result = {:ok, "some_result"}

      {:noreply, updated_socket} =
        ThreatStatementGeneratorComponent.handle_async(:running_llm, async_fun_result, socket)

      assert updated_socket.assigns.async_result.ok? == true
      assert updated_socket.assigns.async_result.result == "some_result"

      async_fun_result = {:error, "some_error"}

      {:noreply, updated_socket} =
        ThreatStatementGeneratorComponent.handle_async(:running_llm, async_fun_result, socket)

      assert updated_socket.assigns.async_result.ok? == false
      assert updated_socket.assigns.async_result.failed == "some_error"
    end
  end

  describe "handle_event/3" do
    setup [:create_component]

    test "generate_again resets the assigns", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :threat, threat_fixture()))

      socket =
        Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %Phoenix.LiveComponent.CID{}))

      {:noreply, updated_socket} =
        ThreatStatementGeneratorComponent.handle_event("generate_again", %{}, socket)

      assert updated_socket.assigns.threat == nil
    end

    test "save a threat statment to the workspace", %{socket: socket} do
      threat =
        threat_fixture()
        |> Map.put(:id, nil)

      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :threat, threat))

      {:noreply, updated_socket} =
        ThreatStatementGeneratorComponent.handle_event("save", %{}, socket)

      assert updated_socket.assigns.threat == nil
      assert length(Valentine.Composer.list_threats()) == 2
      assert Enum.find(Valentine.Composer.list_threats(), &(&1.tags == ["AI generated"])) != nil
    end

    test "returns an error if the threat is nil", %{socket: socket} do
      socket = Map.put(socket, :assigns, Map.put(socket.assigns, :threat, nil))

      {:noreply, updated_socket} =
        ThreatStatementGeneratorComponent.handle_event("save", %{}, socket)

      assert updated_socket.assigns.error == "No threat statement generated"
    end
  end

  describe "update/2" do
    setup [:create_component]

    test "updates the socket with the chat_complete data", %{socket: socket} do
      data = %{
        content:
          Jason.encode!(%{
            "threat_source" => "threat_source",
            "prerequisites" => "prerequisites",
            "threat_action" => "threat_action",
            "threat_impact" => "threat_impact",
            "impacted_goal" => ["impacted_goal"],
            "impacted_assets" => ["impacted_assets"],
            "stride" => ["spoofing"]
          })
      }

      {:ok, updated_socket} =
        ThreatStatementGeneratorComponent.update(%{chat_complete: data}, socket)

      assert updated_socket.assigns.threat == %Valentine.Composer.Threat{
               threat_source: "threat_source",
               prerequisites: "prerequisites",
               threat_action: "threat_action",
               threat_impact: "threat_impact",
               impacted_goal: ["impacted_goal"],
               impacted_assets: ["impacted_assets"],
               stride: [:spoofing]
             }
    end

    test "normalizes scalar impacted_goal and stride values", %{socket: socket} do
      data = %{
        content:
          Jason.encode!(%{
            "threat_source" => "threat_source",
            "prerequisites" => "prerequisites",
            "threat_action" => "threat_action",
            "threat_impact" => "threat_impact",
            "impacted_goal" => "integrity",
            "impacted_assets" => "private repositories",
            "stride" => "tampering"
          })
      }

      {:ok, updated_socket} =
        ThreatStatementGeneratorComponent.update(%{chat_complete: data}, socket)

      assert updated_socket.assigns.threat.impacted_goal == ["integrity"]
      assert updated_socket.assigns.threat.impacted_assets == ["private repositories"]
      assert updated_socket.assigns.threat.stride == [:tampering]
    end

    test "returns an error if the chat_complete data is not valid JSON", %{socket: socket} do
      data = %{
        content: "invalid_json"
      }

      {:ok, updated_socket} =
        ThreatStatementGeneratorComponent.update(%{chat_complete: data}, socket)

      assert updated_socket.assigns.error == "Error decoding response"
    end

    test "updates the socket with the usage_update data", %{socket: socket} do
      usage = %{input_tokens: 0, output_tokens: 0}

      {:ok, updated_socket} =
        ThreatStatementGeneratorComponent.update(%{usage_update: usage}, socket)

      assert updated_socket.assigns.usage == usage
    end

    test "kicks off a new LLM chain run once it is updated", %{assigns: assigns, socket: socket} do
      socket =
        Map.put(socket, :assigns, Map.put(socket.assigns, :myself, %Phoenix.LiveComponent.CID{}))

      {:ok, updated_socket} =
        ThreatStatementGeneratorComponent.update(assigns, socket)

      assert updated_socket.assigns.async_result.loading == true
    end
  end
end
