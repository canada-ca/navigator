defmodule ValentineWeb.WorkspaceLive.WorkspaceAccessTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias Valentine.Composer.Workspaces
  alias Valentine.Composer.Assumptions
  alias Valentine.Composer.EvidenceManagement
  alias Valentine.Composer.Mitigations
  alias Valentine.Composer.Threats
  alias Valentine.Repo

  setup do
    workspace =
      workspace_fixture(%{
        owner: "owner@localhost",
        permissions: %{
          "writer@localhost" => "write",
          "reader@localhost" => "read"
        }
      })

    %{workspace: workspace}
  end

  test "owner, writer, and reader can open readable routes", %{conn: conn, workspace: workspace} do
    for identity <- [workspace.owner, "writer@localhost", "reader@localhost"] do
      conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: identity})

      assert {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.id}/collaboration")
      assert html =~ "Collaboration"
    end
  end

  test "only writers and owners can open write-only routes", %{conn: conn, workspace: workspace} do
    for identity <- [workspace.owner, "writer@localhost"] do
      conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: identity})
      assert {:ok, _view, _html} = live(conn, ~p"/workspaces/#{workspace.id}/assumptions/new")
    end

    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})

    assert {:error, {:redirect, %{to: path}}} =
             live(conn, ~p"/workspaces/#{workspace.id}/assumptions/new")

    assert path == ~p"/workspaces/#{workspace.id}"
  end

  test "reader assumption listing keeps exports and hides creation actions", %{
    conn: conn,
    workspace: workspace
  } do
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})

    assert {:ok, view, _html} =
             live(reader_conn, ~p"/workspaces/#{workspace.id}/assumptions")

    assert has_element?(view, "a", "Export reference pack")
    refute has_element?(view, "button", "New Assumption")
    refute has_element?(view, "button", "Get started")
  end

  test "only owners can open manage-only routes", %{conn: conn, workspace: workspace} do
    owner_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: workspace.owner})
    assert {:ok, _view, _html} = live(owner_conn, ~p"/workspaces/#{workspace.id}/api_keys")

    for identity <- ["writer@localhost", "reader@localhost"] do
      collaborator_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: identity})

      assert {:error, {:redirect, %{to: path}}} =
               live(collaborator_conn, ~p"/workspaces/#{workspace.id}/api_keys")

      assert path == ~p"/workspaces/#{workspace.id}"
    end
  end

  test "readers can export while unshared and invalid-role identities are rejected", %{
    conn: conn,
    workspace: workspace
  } do
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})
    assert get(reader_conn, ~p"/workspaces/#{workspace.id}/export").status == 200

    for identity <- ["unshared@localhost", "legacy@localhost"] do
      workspace =
        if identity == "legacy@localhost" do
          workspace
          |> Ecto.Changeset.change(%{
            permissions: Map.put(workspace.permissions, identity, "member")
          })
          |> Repo.update!()
        else
          workspace
        end

      rejected_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: identity})
      response = get(rejected_conn, ~p"/workspaces/#{workspace.id}/export")

      assert redirected_to(response) == ~p"/workspaces"
    end
  end

  test "reader can open report, review, SRTM, controls, and printable surfaces", %{
    conn: conn,
    workspace: workspace
  } do
    _control = control_fixture()

    run =
      threat_model_quality_review_run_fixture(%{
        workspace_id: workspace.id,
        owner: workspace.owner,
        status: :completed,
        completed_at: DateTime.utc_now()
      })

    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})

    for path <- [
          ~p"/workspaces/#{workspace.id}",
          ~p"/workspaces/#{workspace.id}/threat_model",
          ~p"/workspaces/#{workspace.id}/threat_model?print=true",
          ~p"/workspaces/#{workspace.id}/threat_model/reviews",
          ~p"/workspaces/#{workspace.id}/threat_model/reviews/#{run.id}",
          ~p"/workspaces/#{workspace.id}/srtm",
          ~p"/workspaces/#{workspace.id}/controls"
        ] do
      assert {:ok, _view, _html} = live(reader_conn, path)
    end
  end

  test "reader downloads every workspace export without initializing a diagram", %{
    conn: conn,
    workspace: workspace
  } do
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})

    assert Valentine.Composer.Documents.get_data_flow_diagram_by_workspace_id(workspace.id) == nil

    for path <- [
          ~p"/workspaces/#{workspace.id}/export",
          ~p"/workspaces/#{workspace.id}/export/assumptions",
          ~p"/workspaces/#{workspace.id}/export/mitigations",
          ~p"/workspaces/#{workspace.id}/export/threats",
          ~p"/workspaces/#{workspace.id}/threat_model/markdown",
          ~p"/workspaces/#{workspace.id}/srtm/excel",
          ~p"/workspaces/#{workspace.id}/data_flow/mermaid"
        ] do
      assert get(reader_conn, path).status == 200
    end

    assert Valentine.Composer.Documents.get_data_flow_diagram_by_workspace_id(workspace.id) == nil
  end

  test "unshared identities cannot download any workspace export", %{
    conn: conn,
    workspace: workspace
  } do
    rejected_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "unshared@localhost"})

    for path <- [
          ~p"/workspaces/#{workspace.id}/export",
          ~p"/workspaces/#{workspace.id}/export/assumptions",
          ~p"/workspaces/#{workspace.id}/export/mitigations",
          ~p"/workspaces/#{workspace.id}/export/threats",
          ~p"/workspaces/#{workspace.id}/threat_model/markdown",
          ~p"/workspaces/#{workspace.id}/srtm/excel",
          ~p"/workspaces/#{workspace.id}/data_flow/mermaid"
        ] do
      assert redirected_to(get(rejected_conn, path)) == ~p"/workspaces"
    end
  end

  test "connected sessions apply permission upgrades, downgrades, and removal", %{
    conn: conn,
    workspace: workspace
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})
    {:ok, view, html} = live(conn, ~p"/workspaces/#{workspace.id}/collaboration")

    assert html =~ "workspace-read-only-indicator"
    assert html =~ "Your current permission level is: read"

    assert {:ok, _workspace} =
             Workspaces.update_workspace_permissions(
               workspace,
               workspace.owner,
               "reader@localhost",
               "write"
             )

    refute render(view) =~ "workspace-read-only-indicator"
    assert render(view) =~ "Your current permission level is: write"

    assert {:ok, workspace} =
             Workspaces.update_workspace_permissions(
               workspace,
               workspace.owner,
               "reader@localhost",
               "read"
             )

    assert render(view) =~ "workspace-read-only-indicator"
    assert render(view) =~ "Your current permission level is: read"

    assert {:ok, _workspace} =
             Workspaces.update_workspace_permissions(
               workspace,
               workspace.owner,
               "reader@localhost",
               "none"
             )

    assert_redirect(view, ~p"/workspaces")
  end

  test "reader rich-text pages render a non-editable editor without save controls", %{
    conn: conn,
    workspace: workspace
  } do
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})

    for path <- [
          ~p"/workspaces/#{workspace.id}/application_information",
          ~p"/workspaces/#{workspace.id}/architecture"
        ] do
      assert {:ok, _view, html} = live(reader_conn, path)
      assert html =~ "data-read-only=\"true\""
      assert html =~ "Read only"
      refute html =~ "id=\"quill-save-btn\""
    end
  end

  test "reader data-flow mount and forged graph events do not create or mutate a diagram", %{
    conn: conn,
    workspace: workspace
  } do
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})

    assert Valentine.Composer.Documents.get_data_flow_diagram_by_workspace_id(workspace.id) == nil
    assert {:ok, view, html} = live(reader_conn, ~p"/workspaces/#{workspace.id}/data_flow")

    assert html =~ "data-read-only=\"true\""
    assert html =~ "View options"
    refute html =~ "Add actor"
    refute html =~ "Import Mermaid diagram"

    render_hook(view, "add_node", %{"type" => "actor"})

    assert Valentine.Composer.Documents.get_data_flow_diagram_by_workspace_id(workspace.id) == nil
    assert Valentine.Composer.DataFlowDiagram.load(workspace.id).nodes == %{}

    render_hook(view, "select", %{"id" => "node-1", "label" => "Node", "group" => "nodes"})

    send(view.pid, %{event: "fit_view", payload: nil})
    assert_push_event(view, "updateGraph", %{event: "fit_view", payload: nil})
  end

  test "reader forged mutations and stale writer sockets are rejected from current database state",
       %{
         conn: conn,
         workspace: workspace
       } do
    reader_assumption = assumption_fixture(%{workspace_id: workspace.id, tags: ["reader-tag"]})
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})
    {:ok, reader_view, _html} = live(reader_conn, ~p"/workspaces/#{workspace.id}/assumptions")

    assert_forged_event_inert(reader_view, "delete", %{"id" => reader_assumption.id}, fn ->
      Assumptions.get_assumption!(reader_assumption.id)
    end)

    reader_view
    |> with_target(".Box-row [data-phx-component]")
    |> render_hook("remove_tag", %{"tag" => "reader-tag"})

    assert Assumptions.get_assumption!(reader_assumption.id).tags == ["reader-tag"]

    stale_writer_assumption = assumption_fixture(%{workspace_id: workspace.id})
    writer_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "writer@localhost"})
    {:ok, writer_view, _html} = live(writer_conn, ~p"/workspaces/#{workspace.id}/assumptions")

    workspace
    |> Ecto.Changeset.change(%{
      permissions: Map.put(workspace.permissions, "writer@localhost", "read")
    })
    |> Repo.update!()

    assert_forged_event_inert(writer_view, "delete", %{"id" => stale_writer_assumption.id}, fn ->
      Assumptions.get_assumption!(stale_writer_assumption.id)
    end)
  end

  test "reader core-entity pages remain inspectable without mutation controls", %{
    conn: conn,
    workspace: workspace
  } do
    threat = threat_fixture(%{workspace_id: workspace.id})
    evidence = evidence_fixture(%{workspace_id: workspace.id})
    threat_agent = threat_agent_fixture(%{workspace_id: workspace.id})
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})

    for {path, visible, hidden} <- [
          {~p"/workspaces/#{workspace.id}/threats/#{threat.id}", "Threat Statement", "Save"},
          {~p"/workspaces/#{workspace.id}/evidence/#{evidence.id}", evidence.name, "Save"},
          {~p"/workspaces/#{workspace.id}/threat_agents", threat_agent.name, "New Threat Agent"}
        ] do
      assert {:ok, _view, html} = live(reader_conn, path)
      assert html =~ visible
      refute html =~ hidden
    end
  end

  test "reader forged deletes leave every core entity unchanged", %{
    conn: conn,
    workspace: workspace
  } do
    entities = [
      {~p"/workspaces/#{workspace.id}/assumptions",
       assumption_fixture(%{workspace_id: workspace.id}), &Assumptions.get_assumption!/1},
      {~p"/workspaces/#{workspace.id}/mitigations",
       mitigation_fixture(%{workspace_id: workspace.id}), &Mitigations.get_mitigation!/1},
      {~p"/workspaces/#{workspace.id}/threats", threat_fixture(%{workspace_id: workspace.id}),
       &Threats.get_threat!/1},
      {~p"/workspaces/#{workspace.id}/evidence", evidence_fixture(%{workspace_id: workspace.id}),
       &EvidenceManagement.get_evidence!/1},
      {~p"/workspaces/#{workspace.id}/threat_agents",
       threat_agent_fixture(%{workspace_id: workspace.id}), &Threats.get_threat_agent!/1}
    ]

    for {path, entity, reload} <- entities do
      reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})
      assert {:ok, view, _html} = live(reader_conn, path)

      assert_forged_event_inert(view, "delete", %{"id" => entity.id}, fn ->
        reload.(entity.id)
      end)
    end
  end

  test "permission broadcasts are consumed on pages with application message handlers", %{
    conn: conn,
    workspace: workspace
  } do
    writer_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "writer@localhost"})

    views =
      for path <- [
            ~p"/workspaces/#{workspace.id}/assumptions",
            ~p"/workspaces/#{workspace.id}/application_information",
            ~p"/workspaces/#{workspace.id}/architecture",
            ~p"/workspaces/#{workspace.id}/data_flow",
            ~p"/workspaces/#{workspace.id}/brainstorm"
          ] do
        {:ok, view, _html} = live(writer_conn, path)
        view
      end

    for permission <- ["read", "write"] do
      assert {:ok, _} =
               Workspaces.update_workspace_permissions(
                 workspace,
                 workspace.owner,
                 "writer@localhost",
                 permission
               )

      for view <- views do
        assert has_element?(view, "#workspace-read-only-indicator") == (permission == "read")
      end
    end
  end

  test "readers cannot live-patch from a listing into write-only routes", %{
    conn: conn,
    workspace: workspace
  } do
    reader_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "reader@localhost"})
    {:ok, view, _html} = live(reader_conn, ~p"/workspaces/#{workspace.id}/assumptions")

    render_patch(view, ~p"/workspaces/#{workspace.id}/assumptions/new")
    assert_redirect(view, ~p"/workspaces/#{workspace.id}")
  end

  test "live patches check current permission even when no permission broadcast arrives", %{
    conn: conn,
    workspace: workspace
  } do
    writer_conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: "writer@localhost"})
    {:ok, view, _html} = live(writer_conn, ~p"/workspaces/#{workspace.id}/assumptions")

    workspace
    |> Ecto.Changeset.change(%{
      permissions: Map.put(workspace.permissions, "writer@localhost", "read")
    })
    |> Repo.update!()

    render_patch(view, ~p"/workspaces/#{workspace.id}/assumptions/new")
    assert_redirect(view, ~p"/workspaces/#{workspace.id}")
  end
end
