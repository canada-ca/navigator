defmodule ValentineWeb.Workspace.Markdown do
  def generate(workspace) do
    content(workspace)
  end

  defp content(workspace) do
    ValentineWeb.WorkspaceLive.ThreatModel.Components.MarkdownReportComponent.render(%{
      workspace: workspace
    })
    |> Phoenix.HTML.Safe.to_iodata()
    |> to_string()
    |> String.replace(~r/&lt;/, "<")
    |> String.replace(~r/&gt;/, ">")
    |> String.replace(~r/&amp;/, "&")
    |> String.replace(~r/&quot;/, "\"")
    |> String.replace(~r/&#39;/, "'")
  end
end
