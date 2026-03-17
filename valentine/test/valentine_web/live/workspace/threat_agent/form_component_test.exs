defmodule ValentineWeb.WorkspaceLive.ThreatAgent.FormComponentTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias Valentine.Composer
  alias ValentineWeb.WorkspaceLive.ThreatAgent.Components.FormComponent

  setup do
    threat_agent = threat_agent_fixture()

    assigns = %{
      __changed__: %{},
      threat_agent: threat_agent,
      id: "form-component",
      action: :edit,
      on_cancel: "/workspaces/#{threat_agent.workspace_id}/threat_agents",
      patch: "/workspaces/#{threat_agent.workspace_id}/threat_agents"
    }

    socket = %Phoenix.LiveView.Socket{assigns: assigns}

    %{assigns: assigns, socket: socket, threat_agent: threat_agent}
  end

  test "renders the form", %{assigns: assigns} do
    html = render_component(FormComponent, assigns)

    assert html =~ "Edit Threat Agent"
    assert html =~ "Threat Agent Class"
    assert html =~ "Deliberate Threat Level"
  end

  test "validates required name", %{socket: socket, threat_agent: threat_agent} do
    socket =
      %{
        socket
        | assigns:
            Map.put(
              socket.assigns,
              :changeset,
              Valentine.Composer.change_threat_agent(threat_agent)
            )
      }

    {:noreply, updated_socket} =
      FormComponent.handle_event("validate", %{"threat_agent" => %{"name" => nil}}, socket)

    assert updated_socket.assigns.changeset.valid? == false
  end

  test "saves td_level through the form", %{socket: socket, threat_agent: threat_agent} do
    socket =
      Map.put(socket, :assigns, %{
        __changed__: %{},
        id: "form-component",
        action: :edit,
        threat_agent: threat_agent,
        changeset: Composer.change_threat_agent(threat_agent),
        flash: %{},
        on_cancel: "/workspaces/#{threat_agent.workspace_id}/threat_agents",
        patch: "/workspaces/#{threat_agent.workspace_id}/threat_agents"
      })

    {:noreply, updated_socket} =
      FormComponent.handle_event(
        "save",
        %{
          "threat_agent" => %{
            "name" => threat_agent.name,
            "agent_class" => threat_agent.agent_class,
            "capability" => threat_agent.capability,
            "motivation" => threat_agent.motivation,
            "workspace_id" => threat_agent.workspace_id,
            "td_level" => "td6"
          }
        },
        socket
      )

    assert updated_socket.assigns.flash["info"] =~ "updated successfully"
    assert Composer.get_threat_agent!(threat_agent.id).td_level == :td6
  end
end
