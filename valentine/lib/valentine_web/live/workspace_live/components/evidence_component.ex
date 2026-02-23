defmodule ValentineWeb.WorkspaceLive.Components.EvidenceComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  @impl true
  def render(assigns) do
    ~H"""
    <div class="d-flex flex-items-start flex-justify-between">
      <div class="flex-auto">
        <div class="d-flex flex-items-center">
          <h3 class="f3 text-bold mr-2">
            {@evidence.name}
          </h3>
          <.label class="mr-2">
            {format_evidence_type(@evidence.evidence_type)}
          </.label>
          <.label :if={@evidence.numeric_id} is_secondary class="mr-2">
            #{@evidence.numeric_id}
          </.label>
        </div>

        <p :if={@evidence.description} class="f5 color-fg-muted mb-2">
          {@evidence.description}
        </p>

        <div class="d-flex flex-items-center mb-2">
          <span class="f6 color-fg-muted mr-3">
            <.octicon name="clock-16" class="mr-1" />
            {gettext("Created")}: {format_date(@evidence.inserted_at)}
          </span>
          <span
            :if={@evidence.inserted_at != @evidence.updated_at}
            class="f6 color-fg-muted mr-3"
          >
            <.octicon name="sync-16" class="mr-1" />
            {gettext("Updated")}: {format_date(@evidence.updated_at)}
          </span>
        </div>

        <div :if={length(@evidence.tags) > 0} class="mb-2">
          <span class="f6 color-fg-muted mr-2">{gettext("Tags")}:</span>
          <.label :for={tag <- @evidence.tags} class="mr-1">
            {tag}
          </.label>
        </div>

        <div :if={length(@evidence.nist_controls) > 0} class="mb-2">
          <span class="f6 color-fg-muted mr-2">{gettext("NIST Controls")}:</span>
          <.label :for={control <- @evidence.nist_controls} is_secondary class="mr-1">
            {control}
          </.label>
        </div>
      </div>

      <div class="flex-shrink-0 ml-3 float-right">
        <.button
          is_icon_button
          aria-label="Linked assumptions"
          phx-click={
            JS.patch(~p"/workspaces/#{@evidence.workspace_id}/evidence/#{@evidence.id}/assumptions")
          }
          id={"linked-evidence-assumptions-#{@evidence.id}"}
        >
          <.octicon name="discussion-closed-16" /> {gettext("Assumptions")}
          <.counter>{assoc_length(@evidence.assumptions)}</.counter>
        </.button>
        <.button
          is_icon_button
          aria-label="Linked threats"
          phx-click={
            JS.patch(~p"/workspaces/#{@evidence.workspace_id}/evidence/#{@evidence.id}/threats")
          }
          id={"linked-evidence-threats-#{@evidence.id}"}
        >
          <.octicon name="squirrel-16" /> {gettext("Threats")}
          <.counter>{assoc_length(@evidence.threats)}</.counter>
        </.button>
        <.button
          is_icon_button
          aria-label="Linked mitigations"
          phx-click={
            JS.patch(~p"/workspaces/#{@evidence.workspace_id}/evidence/#{@evidence.id}/mitigations")
          }
          id={"linked-evidence-mitigations-#{@evidence.id}"}
        >
          <.octicon name="check-circle-16" /> {gettext("Mitigations")}
          <.counter>{assoc_length(@evidence.mitigations)}</.counter>
        </.button>
        <.button
          is_icon_button
          navigate={~p"/workspaces/#{@evidence.workspace_id}/evidence/#{@evidence.id}"}
          aria-label={gettext("Edit")}
          id={"edit-evidence-#{@evidence.id}"}
        >
          <.octicon name="pencil-16" />
        </.button>
        <.button
          is_icon_button
          phx-click={JS.push("delete", value: %{id: @evidence.id})}
          data-confirm={gettext("Are you sure you want to delete this evidence?")}
          is_danger
          id={"delete-evidence-#{@evidence.id}"}
        >
          <.octicon name="trash-16" />
        </.button>
      </div>
    </div>
    """
  end

  defp assoc_length(l) when is_list(l), do: length(l)
  defp assoc_length(_), do: 0

  defp format_evidence_type(:json_data), do: "JSON Data"
  defp format_evidence_type(:blob_store_link), do: "File Link"
  defp format_evidence_type(type), do: to_string(type) |> String.capitalize()

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
end
