defmodule ValentineWeb.WorkspaceLive.ThreatModel.Components.ReportComponent do
  use Phoenix.Component
  use PrimerLive

  use Gettext, backend: ValentineWeb.Gettext

  alias ValentineWeb.Helpers.DisplayHelper
  alias ValentineWeb.Helpers.ThreatModelReportHelper

  def render(assigns) do
    threats =
      Enum.reduce(assigns.workspace.threats, %{}, fn threat, acc ->
        Map.put(acc, threat.id, threat)
      end)

    assigns = Map.put(assigns, :threats_by_id, threats)

    ~H"""
    <.styled_html>
      <h3>{gettext("Table of Contents")}</h3>

      <ol>
        <li><a href="#application_information">{gettext("Application Information")}</a></li>
        <li><a href="#architecture">{gettext("Architecture")}</a></li>
        <li><a href="#data_flow_diagram">{gettext("Data Flow")}</a></li>
        <li><a href="#assumptions">{gettext("Assumptions")}</a></li>
        <li><a href="#threats">{gettext("Threats")}</a></li>
        <li><a href="#mitigations">{gettext("Mitigations")}</a></li>
        <li><a href="#impacted_assets">{gettext("Impacted Assets")}</a></li>
      </ol>

      <h3 id="application_information">1. {gettext("Application Information")}</h3>
      {optional_content(@workspace.application_information)
      |> reduce_titles_in_content()
      |> Phoenix.HTML.raw()}

      <h3 id="architecture">2. {gettext("Architecture")}</h3>
      {optional_content(@workspace.architecture) |> reduce_titles_in_content() |> Phoenix.HTML.raw()}

      <h3 id="data_flow_diagram">3. {gettext("Data Flow")}</h3>
      <.box
        :if={@workspace.data_flow_diagram && @workspace.data_flow_diagram.raw_image}
        id="data-flow-diagram-container"
      >
        <img src={@workspace.data_flow_diagram.raw_image} alt="Data flow diagram" />
      </.box>

      <h4>{gettext("Entities")}</h4>
      <table :if={@workspace.data_flow_diagram} class="report-table">
        <thead>
          <tr>
            <th>{gettext("Type")}</th>
            <th>{gettext("Name")}</th>
            <th>{gettext("Description")}</th>
            <th>{gettext("Features")}</th>
            <th>{gettext("Linked threats")}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{_id, entity} <- @workspace.data_flow_diagram.nodes}>
            <td>
              {ThreatModelReportHelper.normalize_type(
                entity["data"]["type"],
                entity["data"]["out_of_scope"]
              )}
            </td>
            <td>{entity["data"]["label"]}</td>
            <td>{entity["data"]["description"]}</td>
            <td>
              <ul :for={key <- ["data_tags", "security_tags", "technology_tags"]}>
                <li :for={value <- entity["data"][key]} :if={value != nil}>
                  {ThreatModelReportHelper.normalize_value(value)}
                </li>
              </ul>
            </td>
            <td>
              <ul>
                <li :for={id <- entity["data"]["linked_threats"]} :if={@threats_by_id[id] != nil}>
                  <a href={"#T-#{@threats_by_id[id].numeric_id}"}>
                    T-{@threats_by_id[id].numeric_id}
                  </a>
                </li>
              </ul>
            </td>
          </tr>
        </tbody>
      </table>
      <h4>{gettext("Data flow definitions")}</h4>
      <table :if={@workspace.data_flow_diagram} class="report-table">
        <thead>
          <tr>
            <th>{gettext("Name")}</th>
            <th>{gettext("Description")}</th>
            <th>{gettext("Source")}</th>
            <th>{gettext("Target")}</th>
            <th>{gettext("Features")}</th>
            <th>{gettext("Linked threats")}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{_id, edge} <- @workspace.data_flow_diagram.edges}>
            <td>{edge["data"]["label"]}</td>
            <td>{edge["data"]["description"]}</td>
            <td>{@workspace.data_flow_diagram.nodes[edge["data"]["source"]]["data"]["label"]}</td>
            <td>{@workspace.data_flow_diagram.nodes[edge["data"]["target"]]["data"]["label"]}</td>
            <td>
              <ul :for={key <- ["data_tags", "security_tags", "technology_tags"]}>
                <li :for={value <- edge["data"][key]} :if={value != nil}>
                  {ThreatModelReportHelper.normalize_value(value)}
                </li>
              </ul>
            </td>
            <td>
              <ul>
                <li :for={id <- edge["data"]["linked_threats"]} :if={@threats_by_id[id] != nil}>
                  <a href={"#T-#{@threats_by_id[id].numeric_id}"}>
                    T-{@threats_by_id[id].numeric_id}
                  </a>
                </li>
              </ul>
            </td>
          </tr>
        </tbody>
      </table>
      <h3 id="assumptions">4. {gettext("Assumptions")}</h3>
      <table class="report-table">
        <thead>
          <tr>
            <th>{gettext("Assumption ID")}</th>
            <th>{gettext("Assumption")}</th>
            <th>{gettext("Linked Threats")}</th>
            <th>{gettext("Linked Mitigations")}</th>
            <th>{gettext("Comments")}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={assumption <- @workspace.assumptions} id={"A-#{assumption.numeric_id}"}>
            <td>A-{assumption.numeric_id}</td>
            <td>{assumption.content}</td>
            <td>
              <ul>
                <li :for={threat <- assumption.threats}>
                  <a href={"#T-#{threat.numeric_id}"}>T-{threat.numeric_id}</a>
                </li>
              </ul>
            </td>
            <td>
              <ul>
                <li :for={mitigation <- assumption.mitigations}>
                  <a href={"#M-#{mitigation.numeric_id}"}>M-{mitigation.numeric_id}</a>
                </li>
              </ul>
            </td>
            <td>
              {to_markdown(assumption.comments)}
            </td>
          </tr>
        </tbody>
      </table>

      <h3 id="threats">5. {gettext("Threats")}</h3>
      <table class="report-table">
        <thead>
          <tr>
            <th>{gettext("Threat ID")}</th>
            <th>{gettext("Threat")}</th>
            <th>{gettext("Assumptions")}</th>
            <th>{gettext("Mitigations")}</th>
            <th>{gettext("Status")}</th>
            <th>{gettext("Priority")}</th>
            <th>{gettext("STRIDE")}</th>
            <th>{gettext("Comments")}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={threat <- @workspace.threats} id={"T-#{threat.numeric_id}"}>
            <td>T-{threat.numeric_id}</td>
            <td>
              {Valentine.Composer.Threat.show_statement(threat)}
            </td>
            <td>
              <ul>
                <li :for={assumption <- threat.assumptions}>
                  <a href={"#A-#{assumption.numeric_id}"}>A-{assumption.numeric_id}</a>
                </li>
              </ul>
            </td>
            <td>
              <ul>
                <li :for={mitigation <- threat.mitigations}>
                  <a href={"#M-#{mitigation.numeric_id}"}>M-{mitigation.numeric_id}</a>
                </li>
              </ul>
            </td>
            <td>{DisplayHelper.enum_label(threat.status)}</td>
            <td>{DisplayHelper.enum_label(threat.priority)}</td>
            <td>{ThreatModelReportHelper.stride_to_letter(threat.stride)}</td>
            <td>
              {to_markdown(threat.comments)}
            </td>
          </tr>
        </tbody>
      </table>

      <h3 id="mitigations">6. {gettext("Mitigations")}</h3>
      <table class="report-table">
        <thead>
          <tr>
            <th>{gettext("Mitigation ID")}</th>
            <th>{gettext("Mitigation")}</th>
            <th>{gettext("Threats Mitigating")}</th>
            <th>{gettext("Assumptions")}</th>
            <th>{gettext("Comments")}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={mitigation <- @workspace.mitigations} id={"M-#{mitigation.numeric_id}"}>
            <td>M-{mitigation.numeric_id}</td>
            <td>{mitigation.content}</td>
            <td>
              <ul>
                <li :for={threat <- mitigation.threats}>
                  <a href={"#T-#{threat.numeric_id}"}>T-{threat.numeric_id}</a>
                </li>
              </ul>
            </td>
            <td>
              <ul>
                <li :for={assumption <- mitigation.assumptions}>
                  <a href={"#A-#{assumption.numeric_id}"}>A-{assumption.numeric_id}</a>
                </li>
              </ul>
            </td>
            <td>
              {to_markdown(mitigation.comments)}
            </td>
          </tr>
        </tbody>
      </table>

      <h3 id="impacted_assets">7. {gettext("Impacted Assets")}</h3>
      <table class="report-table">
        <thead>
          <tr>
            <th>{gettext("Asset ID")}</th>
            <th>{gettext("Asset")}</th>
            <th>{gettext("Related Threats")}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={{{asset, t_ids}, i} <- ThreatModelReportHelper.impacted_assets(@workspace.threats)}
            id={"AS-#{i + 1}"}
          >
            <td>AS-{i + 1}</td>
            <td>{asset}</td>
            <td>
              <ul>
                <li :for={threat_id <- t_ids}>
                  <a href={"#T-#{threat_id}"}>T-{threat_id}</a>
                </li>
              </ul>
            </td>
          </tr>
        </tbody>
      </table>
    </.styled_html>
    """
  end

  defp optional_content(nil), do: "<i>Not set</i>"
  defp optional_content(model), do: model.content

  defp reduce_titles_in_content(content) do
    content
    |> String.replace(~r/h1\>/, "h4>")
    |> String.replace(~r/h2\>/, "h5>")
    |> String.replace(~r/h3\>/, "h6>")
  end

  defp to_markdown(nil), do: ""

  defp to_markdown(text) do
    text
    |> String.trim()
    |> MDEx.to_html!(extension: [shortcodes: true])
    |> Phoenix.HTML.raw()
  end
end
