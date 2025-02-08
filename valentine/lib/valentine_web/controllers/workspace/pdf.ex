defmodule ValentineWeb.Workspace.Pdf do
  def generate(workspace) do
    [
      content: [get_styles(), "<body>", content(workspace), "</body>"],
      size: :us_letter
    ]
    |> ChromicPDF.Template.source_and_options()
    |> ChromicPDF.print_to_pdf()
  end

  defp content(workspace) do
    ValentineWeb.WorkspaceLive.ThreatModel.Components.ReportComponent.render(%{
      workspace: workspace
    })
    |> Phoenix.HTML.Safe.to_iodata()
  end

  defp get_styles() do
    """
    <style>
    /* Basic reset */
    * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    }

    /* Document structure */
    body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    }

    /* Typography */
    h1, h2, h3, h4, h5, h6 {
    margin: 1.5em 0 0.5em;
    line-height: 1.2;
    }

    h1 { font-size: 2em; }
    h2 { font-size: 1.5em; }
    h3 { font-size: 1.3em; }

    p {
    margin-bottom: 1em;
    }

    /* Links */
    a {
    color: #0066cc;
    text-decoration: none;
    }

    a:hover {
    text-decoration: underline;
    }

    /* Tables */
    table {
    width: 100%;
    border-collapse: collapse;
    margin: 1em 0;
    }

    th, td {
    padding: 8px;
    border: 1px solid #ddd;
    text-align: left;
    }

    th {
    background-color: #f5f5f5;
    }

    tr:nth-child(even) {
    background-color: #f9f9f9;
    }

    /* Images */
    img {
    max-width: 100%;
    height: auto;
    margin: 1em 0;
    display: block;
    }

    .diagram-container {
    max-width: 800px;
    margin: 2em auto;
    }

    .diagram-container img {
    width: 100%;
    border: 1px solid #eee;
    border-radius: 4px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    /* Lists */
    ul, ol {
    margin: 1em 0;
    padding-left: 2em;
    }

    li {
    margin-bottom: 0.5em;
    }

    /* Code blocks */
    pre, code {
    font-family: Consolas, Monaco, 'Andale Mono', monospace;
    background: #f5f5f5;
    padding: 0.2em 0.4em;
    border-radius: 3px;
    font-size: 0.9em;
    }

    pre {
    padding: 1em;
    overflow-x: auto;
    margin: 1em 0;
    }

    /* Print styles */
    @media print {
    body {
        max-width: none;
        padding: 2cm;
    }

    img {
        max-width: 100% !important;
        page-break-inside: avoid;
    }

    h1, h2, h3 {
        page-break-after: avoid;
    }

    table {
        page-break-inside: avoid;
    }
    }
    </style>
    """
  end
end
