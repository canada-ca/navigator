defmodule ValentineWeb.WorkspaceLive.SRTM.Index do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Workspace

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)

    filters = %{
      class: [],
      nist_family: [],
      profile: [workspace.cloud_profile],
      type: [workspace.cloud_profile_type]
    }

    controls = filter_controls(filters)

    {:ok,
     socket
     |> assign(:controls, map_controls(controls, workspace))
     |> assign(:nist_families, Composer.list_control_families())
     |> assign(:filters, filters)
     |> assign(:workspace, workspace)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    workspace = socket.assigns.workspace
    controls = filter_controls(%{})

    {
      :noreply,
      socket
      |> assign(:filters, %{})
      |> assign(
        :controls,
        map_controls(controls, workspace)
      )
    }
  end

  @impl true
  def handle_info({:update_filter, filters}, socket) do
    workspace = socket.assigns.workspace
    controls = filter_controls(filters)

    {
      :noreply,
      socket
      |> assign(:filters, filters)
      |> assign(
        :controls,
        map_controls(controls, workspace)
      )
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Security Requirements Traceability Matrix"))
  end

  defp allocated_controls(controls, assumed, mitigated, threats) do
    out_of_scope_ids = Map.keys(assumed)
    in_scope_ids = (Map.keys(mitigated) ++ Map.keys(threats)) |> Enum.uniq()

    initial_acc = %{
      not_allocated: %{},
      out_of_scope: %{},
      in_scope: %{}
    }

    Enum.reduce(controls, initial_acc, fn control, acc ->
      cond do
        control.nist_id in out_of_scope_ids ->
          put_in(
            acc,
            [:out_of_scope, control.nist_id],
            [{control, assumed[control.nist_id]}]
          )

        control.nist_id in in_scope_ids ->
          put_in(
            acc,
            [:in_scope, control.nist_id],
            [{control, (mitigated[control.nist_id] || []) ++ (threats[control.nist_id] || [])}]
          )

        true ->
          put_in(
            acc,
            [:not_allocated, control.nist_id],
            [control]
          )
      end
    end)
  end

  defp filter_controls(filters) when map_size(filters) == 0,
    do: Composer.list_controls()

  defp filter_controls(filters) do
    # This should be dynamically generated
    valid_tags = [
      "CCCS Low Profile for Cloud",
      "CCCS Medium Profile for Cloud",
      "CSP Full Stack",
      "CSP Stacked PaaS",
      "CSP Stacked SaaS",
      "Client IaaS / PaaS",
      "Client SaaS"
    ]

    # Only include valid profile/type tags
    allowed_tags =
      [:profile, :type]
      |> Enum.flat_map(&Map.get(filters, &1, []))
      |> Enum.filter(&(&1 in valid_tags))

    Composer.list_controls_by_filters(%{
      tags: allowed_tags,
      classes: filters[:class] || [],
      nist_families: filters[:nist_family] || []
    })
  end

  defp get_workspace(id) do
    Composer.get_workspace!(id,
      mitigations: [:assumptions, :threats],
      threats: [:assumptions, :mitigations],
      assumptions: [:threats, :mitigations]
    )
  end

  defp item_content(item = %Composer.Threat{}), do: Composer.Threat.show_statement(item)
  defp item_content(item), do: item.content

  defp map_controls(controls, workspace) do
    assumed_controls = Workspace.get_tagged_with_controls(workspace.assumptions)
    mitigated_controls = Workspace.get_tagged_with_controls(workspace.mitigations)
    threat_controls = Workspace.get_tagged_with_controls(workspace.threats)
    allocated_controls(controls, assumed_controls, mitigated_controls, threat_controls)
  end

  defp calculate_percentage(controls, scope) do
    total_controls =
      controls
      |> Map.values()
      |> Enum.map(&map_size/1)
      |> Enum.sum()

    case total_controls do
      0 ->
        0

      _ ->
        scope_count = map_size(controls[scope])
        round(scope_count / total_controls * 100)
    end
  end

  defp scope_progress_class(scope) do
    case scope do
      :not_allocated -> "error"
      :out_of_scope -> "info"
      :in_scope -> "success"
    end
  end
end
