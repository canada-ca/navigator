defmodule ValentineWeb.WorkspaceLive.ThreatModel.ReviewIndex do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Phoenix.PubSub
  alias Valentine.Composer
  alias Valentine.ThreatModelQualityReview

  @impl true
  def mount(%{"workspace_id" => workspace_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Valentine.PubSub, ThreatModelQualityReview.workspace_topic(workspace_id))
    end

    {:ok, assign_workspace(socket, workspace_id)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, gettext("Threat model quality review"))}
  end

  @impl true
  def handle_event("start_threat_model_quality_review", _params, socket) do
    case ThreatModelQualityReview.start_review(
           socket.assigns.workspace_id,
           socket.assigns.current_user
         ) do
      {:ok, _run} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Threat model quality review queued"))
         |> assign_workspace(socket.assigns.workspace_id)}

      {:error, :already_running} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("A threat model quality review is already running for this workspace")
         )}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Workspace not found"))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  @impl true
  def handle_event("cancel_threat_model_quality_review", %{"id" => id}, socket) do
    case ThreatModelQualityReview.cancel_for_owner(id, socket.assigns.current_user) do
      {:ok, _run} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Cancellation requested"))
         |> assign_workspace(socket.assigns.workspace_id)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Quality review not found"))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  @impl true
  def handle_event("delete_threat_model_quality_review", %{"id" => id}, socket) do
    case ThreatModelQualityReview.delete_for_owner(id, socket.assigns.current_user) do
      {:ok, _run} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Quality review deleted"))
         |> assign_workspace(socket.assigns.workspace_id)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Quality review not found"))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  @impl true
  def handle_info(%{event: :threat_model_quality_review_updated}, socket) do
    {:noreply, assign_workspace(socket, socket.assigns.workspace_id)}
  end

  defp assign_workspace(socket, workspace_id) do
    review_history =
      workspace_id
      |> Composer.list_threat_model_quality_review_runs_by_workspace()
      |> Enum.take(10)

    socket
    |> assign(:workspace_id, workspace_id)
    |> assign(:workspace, Composer.get_workspace!(workspace_id))
    |> assign(:review_history, review_history)
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

  defp quality_review_status_label(status), do: DisplayHelper.enum_label(status)

  defp quality_review_status_class(status) when status in [:completed],
    do: "review-runs-table__status-pill--completed"

  defp quality_review_status_class(status) when status in [:failed, :cancelled, :timed_out],
    do: "review-runs-table__status-pill--failed"

  defp quality_review_status_class(status)
       when status in [:queued, :assembling_context, :reviewing, :persisting_results],
       do: "review-runs-table__status-pill--running"

  defp quality_review_status_class(_status), do: nil

  defp quality_review_summary_counts(run) do
    summary = run.result_summary || %{}

    [
      %{
        label: gettext("H"),
        count:
          Map.get(summary, :high_severity_count) || Map.get(summary, "high_severity_count") || 0,
        tone: "high"
      },
      %{
        label: gettext("M"),
        count:
          Map.get(summary, :medium_severity_count) || Map.get(summary, "medium_severity_count") ||
            0,
        tone: "medium"
      },
      %{
        label: gettext("L"),
        count:
          Map.get(summary, :low_severity_count) || Map.get(summary, "low_severity_count") || 0,
        tone: "low"
      },
      %{
        label: gettext("I"),
        count:
          Map.get(summary, :info_severity_count) || Map.get(summary, "info_severity_count") || 0,
        tone: "info"
      }
    ]
  end

  defp quality_review_summary_text(nil), do: nil

  defp quality_review_summary_text(run) do
    summary = run.result_summary || %{}

    if map_size(summary) == 0 do
      nil
    else
      gettext(
        "%{findings} findings: %{high} high, %{medium} medium, %{low} low, %{info} informational",
        findings: Map.get(summary, :finding_count) || Map.get(summary, "finding_count") || 0,
        high:
          Map.get(summary, :high_severity_count) || Map.get(summary, "high_severity_count") || 0,
        medium:
          Map.get(summary, :medium_severity_count) || Map.get(summary, "medium_severity_count") ||
            0,
        low: Map.get(summary, :low_severity_count) || Map.get(summary, "low_severity_count") || 0,
        info:
          Map.get(summary, :info_severity_count) || Map.get(summary, "info_severity_count") || 0
      )
    end
  end
end
