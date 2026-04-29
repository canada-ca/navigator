defmodule ValentineWeb.WorkspaceLive.Components.MarkdownComponent do
  use Phoenix.Component

  attr :text, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="markdown">
      {to_markdown(@text)}
    </div>
    """
  end

  defp to_markdown(nil), do: ""

  defp to_markdown(text) do
    String.trim(text)
    |> MDEx.to_html!(extension: [shortcodes: true], render: [unsafe_: false])
    |> Phoenix.HTML.raw()
  end
end
