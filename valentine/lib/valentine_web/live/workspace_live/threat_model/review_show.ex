defmodule ValentineWeb.WorkspaceLive.ThreatModel.ReviewShow do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Phoenix.PubSub
  alias Valentine.Composer
  alias Valentine.ThreatModelQualityReview

  @impl true
  def mount(%{"workspace_id" => workspace_id, "id" => id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Valentine.PubSub, ThreatModelQualityReview.workspace_topic(workspace_id))
    end

    {:ok, assign_review(socket, workspace_id, id)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, gettext("Threat Model Quality Review"))}
  end

  @impl true
  def handle_info(%{event: :threat_model_quality_review_updated}, socket) do
    {:noreply, assign_review(socket, socket.assigns.workspace_id, socket.assigns.review_run.id)}
  end

  defp assign_review(socket, workspace_id, id) do
    review_run = Composer.get_threat_model_quality_review_run!(id, [:findings, :workspace])

    if review_run.workspace_id != workspace_id do
      raise Ecto.NoResultsError, queryable: Valentine.Composer.ThreatModelQualityReviewRun
    end

    findings = Composer.list_threat_model_quality_review_findings_by_run(id)

    socket
    |> assign(:workspace_id, workspace_id)
    |> assign(:workspace, Composer.get_workspace!(workspace_id))
    |> assign(:review_run, review_run)
    |> assign(:findings, findings)
    |> assign(:summary_counts, summary_counts(review_run, findings))
    |> assign(:grouped_findings, group_findings(findings))
  end

  defp group_findings(findings) do
    severities = [:high, :medium, :low, :info]

    severities
    |> Enum.map(fn severity ->
      {severity, Enum.filter(findings, &(&1.severity == severity))}
    end)
    |> Enum.reject(fn {_severity, items} -> items == [] end)
  end

  defp summary_counts(review_run, findings) do
    summary = review_run.result_summary || %{}

    %{
      finding_count:
        Map.get(summary, :finding_count) || Map.get(summary, "finding_count") || length(findings),
      high:
        Map.get(summary, :high_severity_count) || Map.get(summary, "high_severity_count") ||
          Enum.count(findings, &(&1.severity == :high)),
      medium:
        Map.get(summary, :medium_severity_count) || Map.get(summary, "medium_severity_count") ||
          Enum.count(findings, &(&1.severity == :medium)),
      low:
        Map.get(summary, :low_severity_count) || Map.get(summary, "low_severity_count") ||
          Enum.count(findings, &(&1.severity == :low)),
      info:
        Map.get(summary, :info_severity_count) || Map.get(summary, "info_severity_count") ||
          Enum.count(findings, &(&1.severity == :info))
    }
  end

  defp format_timestamp(datetime) when is_struct(datetime, DateTime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end

  defp format_timestamp(_datetime), do: nil

  defp format_timestamp_with_relative(datetime) when is_struct(datetime, DateTime) do
    "#{format_timestamp(datetime)} (#{relative_timestamp(datetime)})"
  end

  defp format_timestamp_with_relative(_datetime), do: nil

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

  defp severity_section_message(:high),
    do:
      gettext(
        "Address these first because they represent the clearest gaps or inconsistencies in the current model."
      )

  defp severity_section_message(:medium),
    do:
      gettext(
        "These issues are worth resolving next to improve coverage and reduce ambiguity across the model."
      )

  defp severity_section_message(:low),
    do:
      gettext(
        "These items are lower urgency, but tightening them will make the model cleaner and easier to maintain."
      )

  defp severity_section_message(:info),
    do:
      gettext(
        "These observations are informational and may help sharpen structure, wording, or traceability."
      )

  defp severity_label(severity), do: DisplayHelper.enum_label(severity)
  defp category_label(category), do: DisplayHelper.enum_label(category)
end
