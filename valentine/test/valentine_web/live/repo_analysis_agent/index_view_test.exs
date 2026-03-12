defmodule ValentineWeb.RepoAnalysisAgentLive.IndexViewTest do
  use ValentineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  describe "Index" do
    test "lists the current user's repo analysis jobs", %{conn: conn} do
      repo_analysis_agent = repo_analysis_agent_fixture(%{owner: "agent.owner@localhost"})
      _other_repo_analysis_agent = repo_analysis_agent_fixture(%{owner: "other.owner@localhost"})

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "agent.owner@localhost"})

      {:ok, _index_live, html} = live(conn, ~p"/agents")

      assert html =~ "My Agents"
      assert html =~ repo_analysis_agent.github_url
      refute html =~ "other.owner@localhost"
    end

    test "cancels a queued repo analysis job", %{conn: conn} do
      repo_analysis_agent =
        repo_analysis_agent_fixture(%{
          owner: "agent.owner@localhost",
          status: :queued,
          progress_message: "Queued for repository analysis"
        })

      conn = conn |> Phoenix.ConnTest.init_test_session(%{user_id: "agent.owner@localhost"})

      {:ok, index_live, _html} = live(conn, ~p"/agents")

      assert index_live
             |> element("button", "Terminate")
             |> render_click() =~ "Cancellation requested"

      updated_repo_analysis_agent = Valentine.Composer.get_repo_analysis_agent!(repo_analysis_agent.id)
      assert updated_repo_analysis_agent.status == :cancelled
    end
  end
end