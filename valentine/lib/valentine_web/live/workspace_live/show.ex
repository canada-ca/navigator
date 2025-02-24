defmodule ValentineWeb.WorkspaceLive.Show do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"workspace_id" => workspace_id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :workspace,
       Composer.get_workspace!(workspace_id, [:assumptions, :threats, :mitigations])
     )
     |> assign(:workspace_id, workspace_id)}
  end

  defp page_title(:show), do: gettext("Show Workspace")

  defp data_by_field(data, field) do
    data
    |> Enum.group_by(&get_in(&1, [Access.key!(field)]))
    |> Enum.map(fn
      {nil, data} -> {gettext("Not set"), Enum.count(data)}
      {value, data} -> {Phoenix.Naming.humanize(value), Enum.count(data)}
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
    |> Enum.map(fn {category, count} -> {Phoenix.Naming.humanize(category), count} end)
    |> Map.new()
  end

  defp workspace_empty?(workspace) do
    Enum.empty?(workspace.assumptions) &&
      Enum.empty?(workspace.threats) &&
      Enum.empty?(workspace.mitigations)
  end
end
