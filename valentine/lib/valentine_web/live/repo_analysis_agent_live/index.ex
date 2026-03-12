defmodule ValentineWeb.RepoAnalysisAgentLive.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Phoenix.PubSub
  alias Valentine.Composer
  alias Valentine.RepoAnalysis

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Valentine.PubSub, RepoAnalysis.topic(socket.assigns.current_user))
    end

    {:ok,
     socket
     |> assign(
       :repo_analysis_agents,
       Composer.list_repo_analysis_agents_by_owner(socket.assigns.current_user)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("My Agents"))
  end

  @impl true
  def handle_event("cancel", %{"id" => id}, socket) do
    case RepoAnalysis.cancel_for_owner(id, socket.assigns.current_user) do
      {:ok, _repo_analysis_agent} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Cancellation requested"))
         |> reload_agents()}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, gettext("Agent job not found"))}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, inspect(reason))}
    end
  end

  @impl true
  def handle_info(%{event: :repo_analysis_updated}, socket) do
    {:noreply, reload_agents(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.subhead>
      {gettext("My Agents")}
      <:actions>
        <.link navigate={~p"/workspaces"} class="btn">
          {gettext("Back to Workspaces")}
        </.link>
      </:actions>
    </.subhead>

    <.box>
      <:header>{gettext("Repository analysis jobs")}</:header>
      <%= if Enum.empty?(@repo_analysis_agents) do %>
        <.blankslate class="color-bg-default">
          <:octicon name="cpu-24" />
          <:action>
            <.link navigate={~p"/workspaces/import/github"} class="btn btn-primary">
              {gettext("Import from GitHub")}
            </.link>
          </:action>
          <h3>{gettext("No agents yet")}</h3>
          <p>{gettext("Start a GitHub import to create a threat model from a public repository.")}</p>
        </.blankslate>
      <% else %>
        <div class="d-flex flex-column gap-3 p-3">
          <div :for={repo_analysis_agent <- @repo_analysis_agents} class="Box-row d-flex flex-column gap-2">
            <div class="d-flex flex-justify-between flex-items-start gap-3">
              <div>
                <div class="text-bold">
                  {repo_analysis_agent.workspace && repo_analysis_agent.workspace.name || gettext("Pending workspace")}
                </div>
                <div class="color-fg-muted text-small">{repo_analysis_agent.github_url}</div>
              </div>
              <div class="d-flex flex-items-center gap-2">
                <span class="Label">{repo_analysis_agent.status}</span>
                <.button
                  :if={RepoAnalysis.running_status?(repo_analysis_agent.status)}
                  phx-click="cancel"
                  phx-value-id={repo_analysis_agent.id}
                >
                  {gettext("Terminate")}
                </.button>
              </div>
            </div>

            <div>{repo_analysis_agent.progress_message || gettext("Waiting for updates")}</div>

            <progress max="100" value={repo_analysis_agent.progress_percent || 0} style="width: 100%;"></progress>

            <div class="d-flex flex-justify-between color-fg-muted text-small">
              <span>{gettext("Progress: %{percent}%", percent: repo_analysis_agent.progress_percent || 0)}</span>
              <.link :if={repo_analysis_agent.workspace_id} navigate={~p"/workspaces/#{repo_analysis_agent.workspace_id}"}>
                {gettext("Open workspace")}
              </.link>
            </div>

            <div :if={repo_analysis_agent.failure_reason} class="color-fg-danger text-small">
              {repo_analysis_agent.failure_reason}
            </div>
          </div>
        </div>
      <% end %>
    </.box>
    """
  end

  defp reload_agents(socket) do
    assign(
      socket,
      :repo_analysis_agents,
      Composer.list_repo_analysis_agents_by_owner(socket.assigns.current_user)
    )
  end
end
