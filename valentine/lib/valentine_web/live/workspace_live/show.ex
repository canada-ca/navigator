defmodule ValentineWeb.WorkspaceLive.Show do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Phoenix.PubSub
  alias Valentine.Composer
  alias Valentine.RepoAnalysis

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"workspace_id" => workspace_id}, _, socket) do
    if connected?(socket) do
      PubSub.subscribe(Valentine.PubSub, RepoAnalysis.workspace_topic(workspace_id))
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign_workspace(workspace_id)}
  end

  @impl true
  def handle_event("cancel_repo_analysis", %{"id" => id}, socket) do
    case RepoAnalysis.cancel_for_owner(id, socket.assigns.current_user) do
      {:ok, _repo_analysis_agent} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Cancellation requested"))
         |> assign_workspace(socket.assigns.workspace_id)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Agent job not found"))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  @impl true
  def handle_event("retry_repo_analysis", %{"id" => id}, socket) do
    case RepoAnalysis.retry_for_owner(id, socket.assigns.current_user) do
      {:ok, _repo_analysis_agent} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Repository analysis queued"))
         |> assign_workspace(socket.assigns.workspace_id)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Agent job not found"))}

      {:error, :not_retryable} ->
        {:noreply, put_flash(socket, :error, gettext("That job cannot be rerun right now"))}

      {:error, :already_running} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("A repository import is already running for this workspace")
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  @impl true
  def handle_info(%{event: :repo_analysis_updated}, socket) do
    {:noreply, assign_workspace(socket, socket.assigns.workspace_id)}
  end

  defp page_title(:show), do: gettext("Show Workspace")

  defp assign_workspace(socket, workspace_id) do
    repo_analysis_history =
      workspace_id
      |> Composer.list_repo_analysis_agents_by_workspace()
      |> Enum.take(5)

    latest_repo_analysis_agent = List.first(repo_analysis_history)

    socket
    |> assign(
      :workspace,
      Composer.get_workspace!(workspace_id, [:assumptions, :threats, :mitigations])
    )
    |> assign(:workspace_id, workspace_id)
    |> assign(:repo_analysis_history, repo_analysis_history)
    |> assign(:latest_repo_analysis_agent, latest_repo_analysis_agent)
  end

  defp data_by_field(data, field) do
    data
    |> Enum.group_by(&get_in(&1, [Access.key!(field)]))
    |> Enum.map(fn
      {nil, data} -> {gettext("Not set"), Enum.count(data)}
      {value, data} -> {DisplayHelper.enum_label(value), Enum.count(data)}
    end)
    |> Map.new()
  end

  defp threat_stride_count(threats) do
    stride = %{
      spoofing: 0,
      tampering: 0,
      repudiation: 0,
      information_disclosure: 0,
      denial_of_service: 0,
      elevation_of_privilege: 0
    }

    threats
    |> Enum.reduce(stride, fn threat, acc ->
      if threat.stride != nil do
        Enum.reduce(threat.stride, acc, fn category, inner_acc ->
          Map.update(inner_acc, category, 1, &(&1 + 1))
        end)
      else
        acc
      end
    end)
    |> Enum.map(fn {category, count} -> {DisplayHelper.enum_label(category), count} end)
    |> Map.new()
  end

  defp workspace_empty?(workspace) do
    Enum.empty?(workspace.assumptions) &&
      Enum.empty?(workspace.threats) &&
      Enum.empty?(workspace.mitigations)
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

  defp repo_analysis_status_label(status) do
    DisplayHelper.repo_analysis_status_label(status)
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

  defp rerun_label(status) when status in [:failed, :timed_out], do: gettext("Retry import")
  defp rerun_label(_status), do: gettext("Run import again")
end
