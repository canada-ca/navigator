defmodule ValentineWeb.WorkspaceLive.ReferencePacks.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  setup do
    reference_pack_item = reference_pack_item_fixture()
    workspace = workspace_fixture()

    %{
      reference_pack_item: reference_pack_item,
      workspace_id: workspace.id
    }
  end

  describe "Index" do
    test "lists all reference_pack_items", %{
      conn: conn,
      reference_pack_item: reference_pack_item,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces/#{workspace_id}/reference_packs")

      assert html =~ "Reference packs"
      assert html =~ reference_pack_item.collection_name

      assert html =~
               Phoenix.Naming.humanize(reference_pack_item.collection_type)
    end

    test "imports reference packs into workspace", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace_id}/reference_packs")

      assert index_live
             |> element("#import-reference-pack")
             |> render_click() =~
               "Import reference pack"

      assert_patch(index_live, ~p"/workspaces/#{workspace_id}/reference_packs/import")
    end

    test "deletes reference packs", %{
      conn: conn,
      reference_pack_item: reference_pack_item,
      workspace_id: workspace_id
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "some owner"})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/#{workspace_id}/reference_packs")

      assert index_live
             |> element(
               "#delete-reference-pack-#{reference_pack_item.collection_id}-#{reference_pack_item.collection_type}"
             )
             |> render_click()

      refute has_element?(
               index_live,
               "#delete-reference-pack-#{reference_pack_item.collection_id}-#{reference_pack_item.collection_type}"
             )
    end
  end
end
