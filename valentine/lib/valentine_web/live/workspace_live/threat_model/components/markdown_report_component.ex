defmodule ValentineWeb.WorkspaceLive.ThreatModel.Components.MarkdownReportComponent do
  use Phoenix.Component

  use Gettext, backend: ValentineWeb.Gettext

  def render(assigns) do
    threats =
      Enum.reduce(assigns.workspace.threats, %{}, fn threat, acc ->
        Map.put(acc, threat.id, threat)
      end)

    assigns = Map.put(assigns, :threats_by_id, threats)

    ~H"""
    {generate_markdown(@workspace, @threats_by_id)}
    """
  end

  def generate_markdown(workspace, threats_by_id) do
    """
    # #{gettext("Threat Model Report")}

    ## #{gettext("Table of Contents")}

    1. [#{gettext("Application Information")}](#application-information)
    2. [#{gettext("Architecture")}](#architecture)
    3. [#{gettext("Data Flow")}](#data-flow)
    4. [#{gettext("Assumptions")}](#assumptions)
    5. [#{gettext("Threats")}](#threats)
    6. [#{gettext("Mitigations")}](#mitigations)
    7. [#{gettext("Impacted Assets")}](#impacted-assets)

    ## <a name="application-information"></a>1. #{gettext("Application Information")}

    #{optional_content(workspace.application_information)}

    ## <a name="architecture"></a>2. #{gettext("Architecture")}

    #{optional_content(workspace.architecture)}

    ## <a name="data-flow"></a>3. #{gettext("Data Flow")}

    #{if workspace.data_flow_diagram && workspace.data_flow_diagram.raw_image do
      "![Data flow diagram](#{workspace.data_flow_diagram.raw_image})"
    else
      "*No data flow diagram available*"
    end}

    ### #{gettext("Entities")}

    #{if workspace.data_flow_diagram do
      entities_table(workspace.data_flow_diagram.nodes, threats_by_id)
    else
      "*No entities available*"
    end}

    ### #{gettext("Data flow definitions")}

    #{if workspace.data_flow_diagram do
      data_flows_table(workspace.data_flow_diagram.nodes, workspace.data_flow_diagram.edges, threats_by_id)
    else
      "*No data flow definitions available*"
    end}

    ## <a name="assumptions"></a>4. #{gettext("Assumptions")}

    #{assumptions_table(workspace.assumptions)}

    ## <a name="threats"></a>5. #{gettext("Threats")}

    #{threats_table(workspace.threats)}

    ## <a name="mitigations"></a>6. #{gettext("Mitigations")}

    #{mitigations_table(workspace.mitigations)}

    ## <a name="impacted-assets"></a>7. #{gettext("Impacted Assets")}

    #{impacted_assets_table(get_assets(workspace.threats))}
    """
  end

  defp entities_table(nodes, threats_by_id) do
    header =
      "| #{gettext("Type")} | #{gettext("Name")} | #{gettext("Description")} | #{gettext("Features")} | #{gettext("Linked threats")} |\n"

    separator = "|---|---|---|---|---|\n"

    rows =
      Enum.map(nodes, fn {_id, entity} ->
        type = normalize_type(entity["data"]["type"], entity["data"]["out_of_scope"])
        name = entity["data"]["label"]
        description = entity["data"]["description"] || ""

        features =
          Enum.reduce(["data_tags", "security_tags", "technology_tags"], [], fn key, acc ->
            values = entity["data"][key] || []
            values = Enum.filter(values, &(&1 != nil))
            acc ++ Enum.map(values, &normalize/1)
          end)

        features_str = Enum.join(features, ", ")

        linked_threats = entity["data"]["linked_threats"] || []
        linked_threats = Enum.filter(linked_threats, &Map.has_key?(threats_by_id, &1))

        linked_threats_str =
          Enum.map(linked_threats, fn id ->
            threat = threats_by_id[id]
            "[T-#{threat.numeric_id}](#t-#{threat.numeric_id})"
          end)
          |> Enum.join(", ")

        "| #{type} | #{name} | #{description} | #{features_str} | #{linked_threats_str} |\n"
      end)
      |> Enum.join("")

    header <> separator <> rows
  end

  defp data_flows_table(nodes, edges, threats_by_id) do
    header =
      "| #{gettext("Name")} | #{gettext("Description")} | #{gettext("Source")} | #{gettext("Target")} | #{gettext("Features")} | #{gettext("Linked threats")} |\n"

    separator = "|---|---|---|---|---|---|\n"

    rows =
      Enum.map(edges, fn {_id, edge} ->
        name = edge["data"]["label"] || ""
        description = edge["data"]["description"] || ""
        source = nodes[edge["data"]["source"]]["data"]["label"] || ""
        target = nodes[edge["data"]["target"]]["data"]["label"] || ""

        features =
          Enum.reduce(["data_tags", "security_tags", "technology_tags"], [], fn key, acc ->
            values = edge["data"][key] || []
            values = Enum.filter(values, &(&1 != nil))
            acc ++ Enum.map(values, &normalize/1)
          end)

        features_str = Enum.join(features, ", ")

        linked_threats = edge["data"]["linked_threats"] || []
        linked_threats = Enum.filter(linked_threats, &Map.has_key?(threats_by_id, &1))

        linked_threats_str =
          Enum.map(linked_threats, fn id ->
            threat = threats_by_id[id]
            "[T-#{threat.numeric_id}](#t-#{threat.numeric_id})"
          end)
          |> Enum.join(", ")

        "| #{name} | #{description} | #{source} | #{target} | #{features_str} | #{linked_threats_str} |\n"
      end)
      |> Enum.join("")

    header <> separator <> rows
  end

  defp assumptions_table(assumptions) do
    header =
      "| #{gettext("Assumption ID")} | #{gettext("Assumption")} | #{gettext("Linked Threats")} | #{gettext("Linked Mitigations")} | #{gettext("Comments")} |\n"

    separator = "|---|---|---|---|---|\n"

    rows =
      Enum.map(assumptions, fn assumption ->
        id = "A-#{assumption.numeric_id}"
        content = assumption.content || ""

        linked_threats =
          Enum.map(assumption.threats, fn threat ->
            "[T-#{threat.numeric_id}](#t-#{threat.numeric_id})"
          end)
          |> Enum.join(", ")

        linked_mitigations =
          Enum.map(assumption.mitigations, fn mitigation ->
            "[M-#{mitigation.numeric_id}](#m-#{mitigation.numeric_id})"
          end)
          |> Enum.join(", ")

        comments = if assumption.comments, do: html_to_markdown(assumption.comments), else: ""

        "| <a name=\"a-#{assumption.numeric_id}\"></a>#{id} | #{content} | #{linked_threats} | #{linked_mitigations} | #{comments} |\n"
      end)
      |> Enum.join("")

    header <> separator <> rows
  end

  defp threats_table(threats) do
    header =
      "| #{gettext("Threat ID")} | #{gettext("Threat")} | #{gettext("Assumptions")} | #{gettext("Mitigations")} | #{gettext("Status")} | #{gettext("Priority")} | #{gettext("STRIDE")} | #{gettext("Comments")} |\n"

    separator = "|---|---|---|---|---|---|---|---|\n"

    rows =
      Enum.map(threats, fn threat ->
        id = "T-#{threat.numeric_id}"
        content = Valentine.Composer.Threat.show_statement(threat)

        linked_assumptions =
          Enum.map(threat.assumptions, fn assumption ->
            "[A-#{assumption.numeric_id}](#a-#{assumption.numeric_id})"
          end)
          |> Enum.join(", ")

        linked_mitigations =
          Enum.map(threat.mitigations, fn mitigation ->
            "[M-#{mitigation.numeric_id}](#m-#{mitigation.numeric_id})"
          end)
          |> Enum.join(", ")

        status = Phoenix.Naming.humanize(threat.status)
        priority = Phoenix.Naming.humanize(threat.priority)
        stride = stride_to_letter(threat.stride)
        comments = if threat.comments, do: html_to_markdown(threat.comments), else: ""

        "| <a name=\"t-#{threat.numeric_id}\"></a>#{id} | #{content} | #{linked_assumptions} | #{linked_mitigations} | #{status} | #{priority} | #{stride} | #{comments} |\n"
      end)
      |> Enum.join("")

    header <> separator <> rows
  end

  defp mitigations_table(mitigations) do
    header =
      "| #{gettext("Mitigation ID")} | #{gettext("Mitigation")} | #{gettext("Threats Mitigating")} | #{gettext("Assumptions")} | #{gettext("Comments")} |\n"

    separator = "|---|---|---|---|---|\n"

    rows =
      Enum.map(mitigations, fn mitigation ->
        id = "M-#{mitigation.numeric_id}"
        content = mitigation.content || ""

        threats_mitigating =
          Enum.map(mitigation.threats, fn threat ->
            "[T-#{threat.numeric_id}](#t-#{threat.numeric_id})"
          end)
          |> Enum.join(", ")

        linked_assumptions =
          Enum.map(mitigation.assumptions, fn assumption ->
            "[A-#{assumption.numeric_id}](#a-#{assumption.numeric_id})"
          end)
          |> Enum.join(", ")

        comments = if mitigation.comments, do: html_to_markdown(mitigation.comments), else: ""

        "| <a name=\"m-#{mitigation.numeric_id}\"></a>#{id} | #{content} | #{threats_mitigating} | #{linked_assumptions} | #{comments} |\n"
      end)
      |> Enum.join("")

    header <> separator <> rows
  end

  defp impacted_assets_table(assets) do
    header = "| #{gettext("Asset ID")} | #{gettext("Asset")} | #{gettext("Related Threats")} |\n"
    separator = "|---|---|---|\n"

    rows =
      Enum.map(assets, fn {{asset, t_ids}, i} ->
        id = "AS-#{i + 1}"

        related_threats =
          Enum.map(t_ids, fn threat_id ->
            "[T-#{threat_id}](#t-#{threat_id})"
          end)
          |> Enum.join(", ")

        "| <a name=\"as-#{i + 1}\"></a>#{id} | #{asset} | #{related_threats} |\n"
      end)
      |> Enum.join("")

    header <> separator <> rows
  end

  defp get_assets(threats) do
    threats
    |> Enum.filter(&(&1.impacted_assets != [] && &1.impacted_assets != nil))
    |> Enum.reduce(%{}, fn t, acc ->
      Enum.reduce(t.impacted_assets, acc, fn asset, a ->
        Map.update(a, asset, [t.numeric_id], &(&1 ++ [t.numeric_id]))
      end)
    end)
    |> Enum.with_index()
  end

  defp normalize(s), do: String.capitalize(s) |> String.replace("_", " ")

  defp normalize_type(s, "false"), do: normalize(s)
  defp normalize_type(s, "true"), do: normalize(s) <> " (Out of scope)"

  defp optional_content(nil), do: "*Not set*"
  defp optional_content(model), do: html_to_markdown(model.content)

  defp stride_to_letter(nil), do: ""

  defp stride_to_letter(data) do
    data
    |> Enum.map(&Atom.to_string/1)
    |> Enum.map(&String.upcase/1)
    |> Enum.map(&String.first/1)
    |> Enum.join()
  end

  # HTML to Markdown conversion functions

  defp html_to_markdown(nil), do: ""
  defp html_to_markdown(""), do: ""

  defp html_to_markdown(html) do
    html
    |> convert_headings()
    |> convert_paragraphs()
    |> convert_formatting()
    |> convert_links()
    |> convert_lists()
    |> String.trim()
  end

  # Convert HTML headings to Markdown headings
  defp convert_headings(html) do
    html
    |> String.replace(~r/<h1>(.*?)<\/h1>/s, "\n# \\1\n")
    |> String.replace(~r/<h2>(.*?)<\/h2>/s, "\n## \\1\n")
    |> String.replace(~r/<h3>(.*?)<\/h3>/s, "\n### \\1\n")
    |> String.replace(~r/<h4>(.*?)<\/h4>/s, "\n#### \\1\n")
    |> String.replace(~r/<h5>(.*?)<\/h5>/s, "\n##### \\1\n")
    |> String.replace(~r/<h6>(.*?)<\/h6>/s, "\n###### \\1\n")
  end

  # Convert HTML paragraphs to Markdown paragraphs
  defp convert_paragraphs(html) do
    html
    |> String.replace(~r/<p>(.*?)<\/p>/s, "\\1\n\n")
  end

  # Convert HTML formatting to Markdown formatting
  defp convert_formatting(html) do
    html
    |> String.replace(~r/<strong>(.*?)<\/strong>/s, "**\\1**")
    |> String.replace(~r/<b>(.*?)<\/b>/s, "**\\1**")
    |> String.replace(~r/<em>(.*?)<\/em>/s, "*\\1*")
    |> String.replace(~r/<i>(.*?)<\/i>/s, "*\\1*")
    |> String.replace(~r/<u>(.*?)<\/u>/s, "_\\1_")
  end

  # Convert HTML links to Markdown links
  defp convert_links(html) do
    # Replace <a href="url">text</a> with [text](url)
    Regex.replace(~r/<a\s+href=["'](.*?)["']\s*>(.*?)<\/a>/s, html, fn _, url, text ->
      "[#{text}](#{url})"
    end)
  end

  # Convert HTML lists to Markdown lists
  defp convert_lists(html) do
    # First handle ordered lists
    html =
      Regex.replace(~r/<ol>(.*?)<\/ol>/s, html, fn _, list_content ->
        "\n" <> convert_list_items(list_content, true) <> "\n"
      end)

    # Then handle unordered lists
    Regex.replace(~r/<ul>(.*?)<\/ul>/s, html, fn _, list_content ->
      "\n" <> convert_list_items(list_content, false) <> "\n"
    end)
  end

  # Helper to convert list items based on list type
  defp convert_list_items(content, ordered?) do
    # Extract list items
    items = Regex.scan(~r/<li>(.*?)<\/li>/s, content, capture: :all_but_first)

    # Convert each item to Markdown format
    Enum.with_index(items, 1)
    |> Enum.map(fn {[item], index} ->
      if ordered? do
        "#{index}. #{item}"
      else
        "- #{item}"
      end
    end)
    |> Enum.join("\n")
  end
end
