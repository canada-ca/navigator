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

      {:ok, _index_live, html} =
        live(
          conn,
          ~p"/workspaces/#{workspace_id}/srtm"
        )

      assert html =~ "Security Requirements Traceability Matrix"
      assert html =~ control.name
      assert html =~ control.nist_id
    end
  end
end
