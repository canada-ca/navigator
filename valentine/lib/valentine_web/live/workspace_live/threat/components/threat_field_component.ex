defmodule ValentineWeb.WorkspaceLive.Threat.Components.ThreatFieldComponent do
  use ValentineWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      class="float-left border p-1 mx-1 mt-1"
      phx-focus="show_context"
      phx-value-field={@field}
      phx-value-type={@type}
      tabindex="0"
    >
      {render_value(@value, @placeholder)}
    </div>
    """
  end

  defp render_value(nil, placeholder), do: placeholder
  defp render_value("", placeholder), do: placeholder
  defp render_value([], placeholder), do: placeholder
  defp render_value(value, _) when is_binary(value), do: value

  defp render_value(value, _) when is_list(value),
    do: DisplayHelper.join_display_list(value)
end
