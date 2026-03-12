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
  def handle_event("retry", %{"id" => id}, socket) do
    case RepoAnalysis.retry_for_owner(id, socket.assigns.current_user) do
      {:ok, _repo_analysis_agent} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Repository analysis queued"))
         |> reload_agents()}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, gettext("Agent job not found"))}

      {:error, :not_retryable} ->
        {:noreply, socket |> put_flash(:error, gettext("That job cannot be rerun right now"))}

      {:error, :already_running} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("A repository import is already running for this workspace")
         )}

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
        <div class="d-flex flex-column gap-2 p-2">
          <details
            :for={repo_analysis_agent <- @repo_analysis_agents}
            class="Box-row repo-analysis-card"
          >
            <summary class="repo-analysis-collapsible__summary">
              <div class="repo-analysis-collapsible__summary-main">
                <div class="repo-analysis-collapsible__summary-title">
                  {(repo_analysis_agent.workspace && repo_analysis_agent.workspace.name) ||
                    gettext("Pending workspace")}
                </div>
                <div class="repo-analysis-collapsible__summary-subtitle">
                  {repo_analysis_agent.github_url}
                </div>
              </div>
              <div class="repo-analysis-collapsible__summary-side">
                <.link
                  :if={repo_analysis_agent.workspace_id}
                  navigate={~p"/workspaces/#{repo_analysis_agent.workspace_id}"}
                  class="repo-analysis-collapsible__summary-link"
                >
                  {gettext("Open workspace")}
                </.link>
                <.state_label
                  is_small
                  class={repo_analysis_status_class(repo_analysis_agent.status)}
                >
                  <.octicon name={repo_analysis_status_icon(repo_analysis_agent.status)} />
                  {repo_analysis_status_label(repo_analysis_agent.status)}
                </.state_label>
                <span class="repo-analysis-progress-text">
                  {gettext("%{percent}%", percent: repo_analysis_agent.progress_percent || 0)}
                </span>
                <.octicon name="triangle-down-16" class="repo-analysis-collapsible__chevron" />
              </div>
            </summary>

            <div class="repo-analysis-collapsible__content">
              <div class="repo-analysis-card__actions">
                <.button
                  :if={RepoAnalysis.running_status?(repo_analysis_agent.status)}
                  phx-click="cancel"
                  phx-value-id={repo_analysis_agent.id}
                >
                  {gettext("Terminate")}
                </.button>
                <.button
                  :if={RepoAnalysis.rerunnable_status?(repo_analysis_agent.status)}
                  phx-click="retry"
                  phx-value-id={repo_analysis_agent.id}
                >
                  {rerun_label(repo_analysis_agent.status)}
                </.button>
              </div>

              <div class="repo-analysis-card__message">
                {repo_analysis_agent.progress_message || gettext("Waiting for updates")}
              </div>

              <div class="repo-analysis-meta-grid">
                <div class="repo-analysis-meta-item">
                  <div class="repo-analysis-meta-label">{gettext("Requested")}</div>
                  <div class="repo-analysis-meta-value">
                    {format_timestamp_with_relative(
                      repo_analysis_agent.requested_at || repo_analysis_agent.inserted_at
                    )}
                  </div>
                </div>
                <div :if={repo_analysis_agent.started_at} class="repo-analysis-meta-item">
                  <div class="repo-analysis-meta-label">{gettext("Started")}</div>
                  <div class="repo-analysis-meta-value">
                    {format_timestamp_with_relative(repo_analysis_agent.started_at)}
                  </div>
                </div>
                <div :if={repo_analysis_agent.completed_at} class="repo-analysis-meta-item">
                  <div class="repo-analysis-meta-label">{gettext("Completed")}</div>
                  <div class="repo-analysis-meta-value">
                    {format_timestamp_with_relative(repo_analysis_agent.completed_at)}
                  </div>
                </div>
                <div
                  :if={
                    repo_analysis_agent.last_heartbeat_at &&
                      RepoAnalysis.running_status?(repo_analysis_agent.status)
                  }
                  class="repo-analysis-meta-item"
                >
                  <div class="repo-analysis-meta-label">{gettext("Last heartbeat")}</div>
                  <div class="repo-analysis-meta-value">
                    {format_timestamp_with_relative(repo_analysis_agent.last_heartbeat_at)}
                  </div>
                </div>
                <div
                  :if={repo_analysis_agent.cancel_requested_at}
                  class="repo-analysis-meta-item"
                >
                  <div class="repo-analysis-meta-label">{gettext("Cancel requested")}</div>
                  <div class="repo-analysis-meta-value">
                    {format_timestamp_with_relative(repo_analysis_agent.cancel_requested_at)}
                  </div>
                </div>
              </div>

              <div class="repo-analysis-detail-grid">
                <div
                  :if={repo_analysis_agent.repo_full_name || repo_analysis_agent.repo_default_branch}
                  class="repo-analysis-detail-card"
                >
                  <div class="repo-analysis-meta-label">{gettext("Repository")}</div>
                  <div class="repo-analysis-detail-value">{repo_label(repo_analysis_agent)}</div>
                </div>

                <div :if={summary_text(repo_analysis_agent)} class="repo-analysis-detail-card">
                  <div class="repo-analysis-meta-label">{gettext("Generated")}</div>
                  <div class="repo-analysis-detail-value">{summary_text(repo_analysis_agent)}</div>
                </div>
              </div>

              <div class="repo-analysis-progress-block">
                <progress
                  max="100"
                  value={repo_analysis_agent.progress_percent || 0}
                  style="width: 100%;"
                >
                </progress>

                <div class="repo-analysis-progress-row">
                  <span class="repo-analysis-progress-text">
                    {gettext("Progress: %{percent}%",
                      percent: repo_analysis_agent.progress_percent || 0
                    )}
                  </span>
                  <.link
                    :if={repo_analysis_agent.workspace_id}
                    navigate={~p"/workspaces/#{repo_analysis_agent.workspace_id}"}
                  >
                    {gettext("Open workspace")}
                  </.link>
                </div>
              </div>

              <div :if={repo_analysis_agent.failure_reason} class="repo-analysis-alert">
                {repo_analysis_agent.failure_reason}
              </div>
            </div>
          </details>
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

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end

  defp format_timestamp_with_relative(datetime) do
    "#{format_timestamp(datetime)} (#{relative_timestamp(datetime)})"
  end

  defp relative_timestamp(datetime) do
    seconds = max(DateTime.diff(DateTime.utc_now(), datetime, :second), 0)

    cond do
      seconds < 60 ->
        gettext("just now")

      seconds < 3600 ->
        minutes = div(seconds, 60)
        ngettext("%{count} minute ago", "%{count} minutes ago", minutes, count: minutes)

      seconds < 86_400 ->
        hours = div(seconds, 3600)
        ngettext("%{count} hour ago", "%{count} hours ago", hours, count: hours)

      true ->
        days = div(seconds, 86_400)
        ngettext("%{count} day ago", "%{count} days ago", days, count: days)
    end
  end

  defp repo_label(repo_analysis_agent) do
    case {repo_analysis_agent.repo_full_name, repo_analysis_agent.repo_default_branch} do
      {full_name, branch} when is_binary(full_name) and is_binary(branch) and branch != "" ->
        "#{full_name} @ #{branch}"

      {full_name, _branch} when is_binary(full_name) and full_name != "" ->
        full_name

      {_full_name, branch} when is_binary(branch) and branch != "" ->
        branch

      _ ->
        nil
    end
  end

  defp summary_text(repo_analysis_agent) do
    summary = repo_analysis_agent.result_summary || %{}

    if map_size(summary) == 0 do
      nil
    else
      gettext(
        "Generated %{threats} threats, %{assumptions} assumptions, %{mitigations} mitigations, %{components} components, and %{flows} flows",
        threats: Map.get(summary, :threat_count) || Map.get(summary, "threat_count") || 0,
        assumptions:
          Map.get(summary, :assumption_count) || Map.get(summary, "assumption_count") || 0,
        mitigations:
          Map.get(summary, :mitigation_count) || Map.get(summary, "mitigation_count") || 0,
        components:
          Map.get(summary, :component_count) || Map.get(summary, "component_count") || 0,
        flows: Map.get(summary, :flow_count) || Map.get(summary, "flow_count") || 0
      )
    end
  end

  defp rerun_label(status) when status in [:failed, :timed_out], do: gettext("Retry")
  defp rerun_label(_status), do: gettext("Run again")

  defp repo_analysis_status_label(status) do
    status
    |> to_string()
    |> String.replace("_", " ")
    |> Phoenix.Naming.humanize()
  end

  defp repo_analysis_status_class(status) when status in [:completed], do: "State--open"

  defp repo_analysis_status_class(status) when status in [:failed, :cancelled, :timed_out],
    do: "State--closed"

  defp repo_analysis_status_class(_status), do: nil

  defp repo_analysis_status_icon(status) when status in [:completed], do: "check-16"

  defp repo_analysis_status_icon(status) when status in [:failed, :cancelled, :timed_out],
    do: "x-16"

  defp repo_analysis_status_icon(status) when status in [:queued], do: "clock-16"
  defp repo_analysis_status_icon(_status), do: "sync-16"
end
