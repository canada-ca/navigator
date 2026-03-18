defmodule ValentineWeb.WorkspaceLive.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}

  defp create_workspace(_) do
    workspace = workspace_fixture()
    %{workspace: workspace}
  end

  describe "Index" do
    setup [:create_workspace]

    test "lists all workspaces", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, _index_live, html} = live(conn, ~p"/workspaces")

      assert html =~ "Listing Workspaces"
      assert html =~ workspace.name
    end

    test "saves new workspaces", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live |> element("button", "New Workspace") |> render_click() =~
               "New Workspace"

      assert_patch(index_live, ~p"/workspaces/new")

      assert index_live
             |> form("#workspaces-form",
               workspace: @create_attrs
             )
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces")

      html = render(index_live)
      assert html =~ "Workspace created successfully"
      assert html =~ "some name"
    end

    test "updates workspace in listing", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#edit-workspace-#{workspace.id}")
             |> render_click() =~
               "Edit Workspace"

      assert_patch(index_live, ~p"/workspaces/#{workspace.id}/edit")

      assert index_live
             |> form("#workspaces-form", workspace: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/workspaces")

      html = render(index_live)
      assert html =~ "Workspace updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes workspace in listing", %{
      conn: conn,
      workspace: workspace
    } do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: workspace.owner})

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#delete-workspace-#{workspace.id}")
             |> render_click()

      refute has_element?(index_live, "#workspaces-#{workspace.id}")
    end

    test "imports workspace in listing", %{
      conn: conn
    } do
      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#import-workspace-btn")
             |> render_click() =~
               "Import Workspace"

      assert_patch(index_live, ~p"/workspaces/import")
    end

    test "navigates to GitHub import", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#import-github-workspace-btn")
             |> render_click() =~
               "Import from GitHub"

      assert_patch(index_live, ~p"/workspaces/import/github")
    end

    test "validates GitHub import URL and shows cloud profile labels", %{conn: conn} do
      {:ok, index_live, html} = live(conn, ~p"/workspaces/import/github")

      assert html =~ "Cloud Profile"
      assert html =~ "Cloud Profile Type"

      html =
        index_live
        |> form("#github-import-form", import: %{github_url: "not-a-github-url"})
        |> render_change()

      assert html =~ "Only public GitHub repository URLs are supported"
    end

    test "shows a validation error for a private GitHub repository URL", %{conn: conn} do
      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "workspace-index-private-url-test-#{System.unique_integer([:positive])}"
        )

      fake_bin_dir = Path.join(temp_dir, "bin")
      fake_git_path = Path.join(fake_bin_dir, "git")
      original_path = System.get_env("PATH") || ""
      repo_analysis_config = Application.get_env(:valentine, :repo_analysis, [])

      File.mkdir_p!(fake_bin_dir)

      File.write!(
        fake_git_path,
        "#!/bin/sh\nprintf \"fatal: could not read Username for 'https://github.com': terminal prompts disabled\\n\"\nexit 128\n"
      )

      File.chmod!(fake_git_path, 0o755)
      System.put_env("PATH", fake_bin_dir <> ":" <> original_path)

      Application.put_env(
        :valentine,
        :repo_analysis,
        Keyword.merge(repo_analysis_config,
          verify_repo_access: true,
          repo_access_timeout_ms: 100
        )
      )

      on_exit(fn ->
        System.put_env("PATH", original_path)
        Application.put_env(:valentine, :repo_analysis, repo_analysis_config)
        File.rm_rf(temp_dir)
      end)

      {:ok, index_live, _html} = live(conn, ~p"/workspaces/import/github")

      html =
        index_live
        |> form("#github-import-form",
          import: %{github_url: "https://github.com/example/private-repo/pulls"}
        )
        |> render_change()

      assert html =~
               "Repository is private or inaccessible; only public GitHub repositories are supported"
    end

    test "shows My Agents entry", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/workspaces")

      assert html =~ "My Agents"
    end
  end
end
