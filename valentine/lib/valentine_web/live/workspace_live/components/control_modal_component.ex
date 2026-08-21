defmodule ValentineWeb.WorkspaceLive.Components.ControlModalComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Composer.Controls

  def mount(socket) do
    {:ok, assign(socket, nist_id: nil)}
  end

  def render(assigns) do
    assigns = Map.put(assigns, :control, Controls.get_control_by_nist_id(assigns.nist_id))

    ~H"""
    <div>
      <.dialog
        :if={@control != nil}
        is_show
        is_backdrop
        backdrop_strength="light"
        is_fast
        is_wide
        id="control-dialog"
        on_cancel={JS.push("view_control_modal", value: %{nist_id: nil})}
      >
        <:header_title>{@nist_id}: {@control.name}</:header_title>
        <:body>
          <div style="box-sizing:border-box; overflow:hidden; word-wrap:anywhere;">
            {text_to_html(@control.description)}
          </div>
        </:body>
      </.dialog>
    </div>
    """
  end

  defp text_to_html(text) do
    text
    |> String.replace(~r/\n/, "<br>")
    |> String.replace(~r/\s/, "&nbsp;")
    |> String.replace(~r/\t/, "&nbsp;&nbsp;&nbsp;&nbsp;")
    |> Phoenix.HTML.raw()
  end
end
