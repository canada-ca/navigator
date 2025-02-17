defmodule ValentineWeb.WorkspaceLive.Mitigation.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  @create_attrs %{content: "some content", workspace_id: nil}
  @update_attrs %{content: "some updated content"}

  defp create_mitigation(_) do
    mitigation = mitigation_fixture()
    %{mitigation: mitigation, workspace_id: mitigation.workspace_id}
  end

  describe "Index" do
    setup [:create_mitigation]

    test "lists all mitigations", %{
      conn: conn,
      mitigation: mitigation,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace_id}/mitigations")

      assert html =~ "Listing Mitigations"
      assert html =~ mitigation.content
    end

    test "saves new mitigations", %{conn: conn, workspace_id: workspace_id} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace_id}/mitigations")

      assert index_live |> element("button", "New Mitigation") |> render_click() =~
               "New Mitigation"

      assert_patch(index_live, ~p"/workspaces/#{workspace_id}/mitigations/new")

      assert index_live
             |> form("#mitigations-form",
               mitigation: %{@create_attrs | workspace_id: workspace_id}
             )
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces/#{workspace_id}/mitigations")

      html = render(index_live)
      assert html =~ "Mitigation created successfully"
      assert html =~ "some content"
    end

    test "updates mitigation in listing", %{
      conn: conn,
      mitigation: mitigation,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace_id}/mitigations")

      assert index_live
             |> element("#edit-mitigation-#{mitigation.id}")
             |> render_click() =~
               "Edit Mitigation"

      assert_patch(index_live, ~p"/workspaces/#{workspace_id}/mitigations/#{mitigation}/edit")

      assert index_live
             |> form("#mitigations-form", mitigation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces/#{workspace_id}/mitigations")

      html = render(index_live)
      assert html =~ "Mitigation updated successfully"
      assert html =~ "some updated content"
    end

    test "deletes mitigation in listing", %{
      conn: conn,
      mitigation: mitigation,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace_id}/mitigations")

      assert index_live
             |> element("#delete-mitigation-#{mitigation.id}")
             |> render_click()

      refute has_element?(index_live, "#mitigations-#{mitigation.id}")
    end
  end
end
