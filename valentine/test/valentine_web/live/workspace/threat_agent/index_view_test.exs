defmodule ValentineWeb.WorkspaceLive.ThreatAgent.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  test "lists all threat agents", %{conn: conn} do
    threat_agent =
      threat_agent_fixture(%{
        name: "GC End User",
        agent_class: "external_user",
        capability: "basic_access",
        motivation: "financial_gain",
        td_level: :td2
      })

    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "some owner"})

    {:ok, _index_live, html} =
      live(conn, ~p"/workspaces/#{threat_agent.workspace_id}/threat_agents")

    assert html =~ "Listing Threat Agents"
    assert html =~ "GC End User"
    assert html =~ "Class"
    assert html =~ "External user"
    assert html =~ "Capability"
    assert html =~ "Basic access"
    assert html =~ "Motivation"
    assert html =~ "Financial gain"
    assert html =~ "Td2 - Low-Sophistication Insider"
    refute html =~ "Td: Td2 - Low-Sophistication Insider"
  end
end
