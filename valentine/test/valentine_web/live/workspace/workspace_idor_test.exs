defmodule ValentineWeb.WorkspaceLive.WorkspaceIdorTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias Valentine.Composer

  test "forged delete events cannot delete records from another workspace", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "attacker@localhost"})
    other_workspace = workspace_fixture(%{owner: "other.owner@localhost"})

    assumption = assumption_fixture(%{workspace_id: other_workspace.id})
    mitigation = mitigation_fixture(%{workspace_id: other_workspace.id})
    threat = threat_fixture(%{workspace_id: other_workspace.id})
    evidence = evidence_fixture(%{workspace_id: other_workspace.id})
    threat_agent = threat_agent_fixture(%{workspace_id: other_workspace.id})

    api_key = api_key_fixture(%{workspace_id: other_workspace.id})

    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: workspace.owner})

    attempts = [
      {
        "/workspaces/#{workspace.id}/assumptions",
        assumption.id,
        fn -> Composer.get_assumption!(assumption.id) end
      },
      {
        "/workspaces/#{workspace.id}/mitigations",
        mitigation.id,
        fn -> Composer.get_mitigation!(mitigation.id) end
      },
      {
        "/workspaces/#{workspace.id}/threats",
        threat.id,
        fn -> Composer.get_threat!(threat.id) end
      },
      {
        "/workspaces/#{workspace.id}/evidence",
        evidence.id,
        fn -> Composer.get_evidence!(evidence.id) end
      },
      {
        "/workspaces/#{workspace.id}/threat_agents",
        threat_agent.id,
        fn -> Composer.get_threat_agent!(threat_agent.id) end
      },
      {
        "/workspaces/#{workspace.id}/api_keys",
        api_key.id,
        fn -> Composer.get_api_key(api_key.id) end
      }
    ]

    Enum.each(attempts, fn {path, foreign_id, reload} ->
      {:ok, view, _html} = live(conn, path)

      view
      |> render_hook("delete", %{"id" => foreign_id})

      assert reload.()
    end)
  end

  test "forged form workspace IDs cannot move records between workspaces", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "attacker@localhost"})
    other_workspace = workspace_fixture(%{owner: "other.owner@localhost"})
    assumption = assumption_fixture(%{workspace_id: workspace.id})
    mitigation = mitigation_fixture(%{workspace_id: workspace.id})
    threat = threat_fixture(%{workspace_id: workspace.id})
    threat_agent = threat_agent_fixture(%{workspace_id: workspace.id})

    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: workspace.owner})

    {:ok, assumption_view, _html} =
      live(conn, "/workspaces/#{workspace.id}/assumptions/#{assumption.id}/edit")

    assumption_view
    |> element("#assumptions-form")
    |> render_submit(%{
      "assumption" => %{
        "content" => "updated assumption",
        "workspace_id" => other_workspace.id
      }
    })

    {:ok, mitigation_view, _html} =
      live(conn, "/workspaces/#{workspace.id}/mitigations/#{mitigation.id}/edit")

    mitigation_view
    |> element("#mitigations-form")
    |> render_submit(%{
      "mitigation" => %{
        "content" => "updated mitigation",
        "workspace_id" => other_workspace.id
      }
    })

    {:ok, threat_agent_view, _html} =
      live(conn, "/workspaces/#{workspace.id}/threat_agents/#{threat_agent.id}/edit")

    threat_agent_view
    |> element("#threat-agents-form")
    |> render_submit(%{
      "threat_agent" => %{
        "name" => "Updated threat agent",
        "workspace_id" => other_workspace.id
      }
    })

    {:ok, threat_view, _html} =
      live(conn, "/workspaces/#{workspace.id}/threats/#{threat.id}")

    render_hook(threat_view, "update_field", %{
      "_target" => ["workspace_id"],
      "workspace_id" => other_workspace.id
    })

    render_hook(threat_view, "save", %{})

    assert Composer.get_assumption!(assumption.id).workspace_id == workspace.id
    assert Composer.get_mitigation!(mitigation.id).workspace_id == workspace.id
    assert Composer.get_threat!(threat.id).workspace_id == workspace.id
    assert Composer.get_threat_agent!(threat_agent.id).workspace_id == workspace.id
  end

  test "nested routes reject IDs belonging to another workspace", %{conn: conn} do
    workspace = workspace_fixture(%{owner: "attacker@localhost"})
    other_workspace = workspace_fixture(%{owner: "other.owner@localhost"})
    assumption = assumption_fixture(%{workspace_id: other_workspace.id})
    mitigation = mitigation_fixture(%{workspace_id: other_workspace.id})
    threat = threat_fixture(%{workspace_id: other_workspace.id})
    evidence = evidence_fixture(%{workspace_id: other_workspace.id})
    threat_agent = threat_agent_fixture(%{workspace_id: other_workspace.id})

    review_run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: other_workspace.id,
        owner: other_workspace.owner
      })

    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: workspace.owner})

    paths = [
      "/workspaces/#{workspace.id}/assumptions/#{assumption.id}/edit",
      "/workspaces/#{workspace.id}/mitigations/#{mitigation.id}/edit",
      "/workspaces/#{workspace.id}/threats/#{threat.id}",
      "/workspaces/#{workspace.id}/evidence/#{evidence.id}",
      "/workspaces/#{workspace.id}/threat_agents/#{threat_agent.id}/edit",
      "/workspaces/#{workspace.id}/threat_model/reviews/#{review_run.id}"
    ]

    Enum.each(paths, fn path ->
      assert_raise Ecto.NoResultsError, fn -> live(conn, path) end
    end)
  end
end
