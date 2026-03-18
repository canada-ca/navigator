defmodule ValentineWeb.WorkspaceLive.BrainstormTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  @create_attrs %{
    type: "threat",
    text: "Sample threat for testing"
  }

  defp create_brainstorm_item(workspace) do
    brainstorm_item_fixture(%{workspace_id: workspace.id, type: :threat, raw_text: "Test threat"})
  end

  defp create_candidate_item(workspace, type, raw_text) do
    item = brainstorm_item_fixture(%{workspace_id: workspace.id, type: type, raw_text: raw_text})
    {:ok, item} = Valentine.Composer.update_brainstorm_item(item, %{status: :clustered})
    {:ok, item} = Valentine.Composer.update_brainstorm_item(item, %{status: :candidate})
    item
  end

  describe "Index" do
    setup [:create_workspace]

    test "lists all brainstorm items", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert html =~ "Brainstorm Board"
      assert html =~ brainstorm_item.raw_text
    end

    test "creates brainstorm item", %{conn: conn, workspace: workspace} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Submit the form directly since it's always visible
      assert index_live
             |> form("form[phx-submit=\"create_item\"]", %{
               type: "threat",
               text: @create_attrs.text
             })
             |> render_submit()

      html = render(index_live)
      assert html =~ @create_attrs.text
    end

    test "updates brainstorm item", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Start editing by clicking on the item text div (not the menu item)
      assert index_live
             |> element(
               "div[phx-click=\"start_editing\"][phx-value-id=\"#{brainstorm_item.id}\"]"
             )
             |> render_click() =~
               "Save"

      # Submit the edit form
      assert index_live
             |> form(
               "form[phx-submit=\"update_item\"]",
               %{item_id: brainstorm_item.id, text: "Updated threat text"}
             )
             |> render_submit()

      html = render(index_live)
      assert html =~ "Item updated successfully"
      assert html =~ "Updated threat text"
    end

    test "deletes brainstorm item", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert index_live
             |> element("[phx-click=\"delete_item\"][phx-value-id=\"#{brainstorm_item.id}\"]")
             |> render_click()

      html = render(index_live)
      assert html =~ "Item deleted"
      refute html =~ brainstorm_item.raw_text
    end

    test "updates item status", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Update status to clustered
      assert index_live
             |> element(
               "[phx-click=\"update_status\"][phx-value-id=\"#{brainstorm_item.id}\"][phx-value-status=\"clustered\"]"
             )
             |> render_click()

      html = render(index_live)
      assert html =~ "Status updated successfully"
      assert html =~ "Clustered"
    end

    test "filters brainstorm items by status", %{conn: conn, workspace: workspace} do
      _draft_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Filter by archived status (should show no items)
      assert index_live
             |> element("select[id=\"status-filter\"]")
             |> render_change(%{filter_status: "archived"})

      html = render(index_live)
      # Should show empty state since no archived items exist
      assert html =~ "Start Brainstorming!"
    end

    test "searches brainstorm items", %{conn: conn, workspace: workspace} do
      brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Search for specific text
      assert index_live
             |> element("input[id=\"search-filter\"]")
             |> render_change(%{search: "Test"})

      html = render(index_live)
      assert html =~ brainstorm_item.raw_text

      # Search for non-existent text
      assert index_live
             |> element("input[id=\"search-filter\"]")
             |> render_change(%{search: "NonExistent"})

      html = render(index_live)
      # Should show empty state when no results
      assert html =~ "Start Brainstorming!"
    end

    test "clears filters", %{conn: conn, workspace: workspace} do
      _brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      # Apply a filter first
      assert index_live
             |> element("input[id=\"search-filter\"]")
             |> render_change(%{search: "NonExistent"})

      # Clear filters
      assert index_live |> element("button", "Clear") |> render_click()

      html = render(index_live)
      assert html =~ "Test threat"
    end

    test "disables build threat until required eligible cards exist", %{
      conn: conn,
      workspace: workspace
    } do
      _brainstorm_item = create_brainstorm_item(workspace)
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert html =~ "Build Threat"

      assert html =~
               "Add or promote Threat, Attack Vector, Impact, Asset cards to Candidate or Used to unlock the builder."
    end

    test "opens the threat builder when required candidate cards exist", %{
      conn: conn,
      workspace: workspace
    } do
      create_candidate_item(workspace, :threat, "external attacker")
      create_candidate_item(workspace, :attack_vector, "steals a session token")
      create_candidate_item(workspace, :impact, "accesses privileged data")
      create_candidate_item(workspace, :asset, "customer portal")

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert index_live |> element("button", "Build Threat") |> render_click()

      html = render(index_live)
      assert html =~ "Statement Builder"
      assert html =~ "Only Candidate and Used cards appear here"
      assert html =~ "Select threat..."
      refute html =~ "Add or promote Threat, Attack Vector, Impact, Asset cards"
    end

    test "selecting required cards clears validation and renders preview", %{
      conn: conn,
      workspace: workspace
    } do
      threat = create_candidate_item(workspace, :threat, "external attacker")
      attack_vector = create_candidate_item(workspace, :attack_vector, "steals a session token")
      impact = create_candidate_item(workspace, :impact, "accesses privileged data")
      asset = create_candidate_item(workspace, :asset, "customer portal")

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert index_live |> element("button", "Build Threat") |> render_click()

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{"_target" => ["threat"], "threat" => threat.id})

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["attack_vector"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id
             })

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["impact"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id,
               "impact" => impact.id
             })

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["asset"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id,
               "impact" => impact.id,
               "asset" => asset.id
             })

      html = render(index_live)
      refute html =~ "Select a Threat card"
      refute html =~ "Select a Attack Vector card"
      refute html =~ "Select a Impact card"
      refute html =~ "Select a Asset card"
      assert html =~ "external attacker"
      assert html =~ "steals a session token"
      assert html =~ "accesses privileged data"
      assert html =~ "customer portal"
      assert html =~ "1 threat will be created"
    end

    test "selecting multiple assets includes all selected assets in the preview", %{
      conn: conn,
      workspace: workspace
    } do
      threat = create_candidate_item(workspace, :threat, "external attacker")
      attack_vector = create_candidate_item(workspace, :attack_vector, "steals a session token")
      impact = create_candidate_item(workspace, :impact, "accesses privileged data")
      asset_one = create_candidate_item(workspace, :asset, "customer portal")
      asset_two = create_candidate_item(workspace, :asset, "billing service")

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert index_live |> element("button", "Build Threat") |> render_click()

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{"_target" => ["threat"], "threat" => threat.id})

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["attack_vector"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id
             })

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["impact"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id,
               "impact" => impact.id
             })

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["asset"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id,
               "impact" => impact.id,
               "asset" => [asset_one.id, asset_two.id]
             })

      html = render(index_live)
      assert html =~ "customer portal"
      assert html =~ "billing service"
    end

    test "preview hides stride banner when no stride category is inferred", %{
      conn: conn,
      workspace: workspace
    } do
      threat = create_candidate_item(workspace, :threat, "external attacker")
      attack_vector = create_candidate_item(workspace, :attack_vector, "observes normal traffic")
      impact = create_candidate_item(workspace, :impact, "delays incident detection")
      asset = create_candidate_item(workspace, :asset, "customer portal")

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})
      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace.id}/brainstorm")

      assert index_live |> element("button", "Build Threat") |> render_click()

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{"_target" => ["threat"], "threat" => threat.id})

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["attack_vector"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id
             })

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["impact"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id,
               "impact" => impact.id
             })

      assert index_live
             |> element("form.threat-builder-selection-form")
             |> render_change(%{
               "_target" => ["asset"],
               "threat" => threat.id,
               "attack_vector" => attack_vector.id,
               "impact" => impact.id,
               "asset" => [asset.id]
             })

      html = render(index_live)
      refute html =~ ">STRIDE<"
      refute html =~ "Label--accent"
    end
  end

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end
end
