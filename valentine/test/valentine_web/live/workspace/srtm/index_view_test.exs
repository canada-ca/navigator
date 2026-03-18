defmodule ValentineWeb.WorkspaceLive.SRTM.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  setup do
    control = control_fixture(%{nist_id: "AC-1", tags: ["A", "B", "C"]})
    workspace = workspace_fixture(%{cloud_profile: "A", cloud_profile_type: "B"})

    %{
      control: control,
      workspace_id: workspace.id
    }
  end

  describe "Index" do
    test "lists all controls", %{
      conn: conn,
      control: control,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/srtm"
        )

      assert html =~ "Security Requirements Traceability Matrix"

      # Click the "Not allocated" tab to see the control
      html =
        index_live
        |> element("button[phx-click='set_tab'][phx-value-item='not_allocated']")
        |> render_click()

      assert html =~ control.name
      assert html =~ control.nist_id
    end

    test "displays tabs in correct order", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/srtm"
        )

      # Verify tabs appear in correct order within tabnav component
      assert html =~ ~r/tabnav-container.*?In scope.*?Out of scope.*?Not allocated/s
    end

    test "displays summary boxes in correct order", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/srtm"
        )

      # Find positions of summary box headers (f4 class) and verify order
      {in_scope_pos, _} = :binary.match(html, "<div class=\"f4\">In scope</div>")
      {out_of_scope_pos, _} = :binary.match(html, "<div class=\"f4\">Out of scope</div>")
      {not_allocated_pos, _} = :binary.match(html, "<div class=\"f4\">Not allocated</div>")

      # Verify In scope comes before Out of scope, which comes before Not allocated
      assert in_scope_pos < out_of_scope_pos
      assert out_of_scope_pos < not_allocated_pos
    end
  end
end
