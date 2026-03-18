defmodule ValentineWeb.WorkspaceLive.Components.DataFlowMetadataComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  def update(assigns, socket) do
    dfd = Valentine.Composer.DataFlowDiagram.get(assigns.workspace_id)

    element = resolve_element(dfd, assigns.element_id)

    threats =
      if element do
        Valentine.Composer.list_threats_by_ids(element["data"]["linked_threats"])
      else
        []
      end

    {:ok,
     socket
     |> assign(:element, element)
     |> assign(:threats, threats)}
  end

  defp resolve_element(dfd, element_id) do
    cond do
      Map.has_key?(dfd.nodes, element_id) -> dfd.nodes[element_id]
      Map.has_key?(dfd.edges, element_id) -> dfd.edges[element_id]
      true -> nil
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box :if={@element} class="p-4 mt-2">
        <h3>Properties</h3>
        <div class="clearfix">
          <div class="float-left col-4 p-2">
            <.text_input
              name="name"
              placeholder="Set a name"
              input_id="data-element-name"
              is_form_control
              autocomplete="off"
              value={@element["data"]["label"]}
              phx-keyup="update_metadata"
              phx-value-id={@element["data"]["id"]}
              phx-value-field="label"
              is_full_width
              class="mb-2"
            />
            <.textarea
              name="description"
              placeholder="Add a description..."
              input_id="data-element-description"
              is_full_width
              rows="3"
              is_form_control
              value={@element["data"]["description"]}
              phx-keyup="update_metadata"
              phx-value-id={@element["data"]["id"]}
              phx-value-field="description"
              class="mb-2"
            />
            <label>Data features</label>
            <.action_menu
              is_dropdown_caret
              id="data-element-data-tags"
              class="mb-2 data-element-action-menu"
            >
              <:toggle>
                Select data features
                <%= if is_list(@element["data"]["data_tags"]) && length(@element["data"]["data_tags"]) > 0 do %>
                  <.counter>
                    {length(@element["data"]["data_tags"])}
                  </.counter>
                <% end %>
              </:toggle>
              <.action_list is_multiple_select>
                <%= for {section, values} <- data_options(@element["data"]["type"]) do %>
                  <.action_list_section_divider>
                    <:title>{Phoenix.Naming.humanize(section)}</:title>
                  </.action_list_section_divider>
                  <%= for value <- values do %>
                    <.action_list_item
                      field={:data_tags}
                      checked_value={value}
                      is_multiple_select
                      phx-click="update_metadata"
                      phx-value-id={@element["data"]["id"]}
                      phx-value-field="data_tags"
                      phx-value-checked={value}
                      is_selected={value in @element["data"]["data_tags"]}
                    >
                      {Phoenix.Naming.humanize(value)}
                    </.action_list_item>
                  <% end %>
                <% end %>
              </.action_list>
            </.action_menu>
            <label>Security features</label>
            <.action_menu
              is_dropdown_caret
              id="data-element-security-tags"
              class="mb-2 data-element-action-menu"
            >
              <:toggle>
                Select security features
                <%= if is_list(@element["data"]["security_tags"]) && length(@element["data"]["security_tags"]) > 0 do %>
                  <.counter>
                    {length(@element["data"]["security_tags"])}
                  </.counter>
                <% end %>
              </:toggle>
              <.action_list is_multiple_select>
                <%= for {section, values} <- security_options(@element["data"]["type"]) do %>
                  <.action_list_section_divider>
                    <:title>{Phoenix.Naming.humanize(section)}</:title>
                  </.action_list_section_divider>
                  <%= for value <- values do %>
                    <.action_list_item
                      field={:security_tags}
                      checked_value={value}
                      is_multiple_select
                      phx-click="update_metadata"
                      phx-value-id={@element["data"]["id"]}
                      phx-value-field="security_tags"
                      phx-value-checked={value}
                      is_selected={value in @element["data"]["security_tags"]}
                    >
                      {Phoenix.Naming.humanize(value)}
                    </.action_list_item>
                  <% end %>
                <% end %>
              </.action_list>
            </.action_menu>
            <label>Technology features</label>
            <.action_menu
              is_dropdown_caret
              id="data-element-technology-tags"
              class="data-element-action-menu mb-2"
            >
              <:toggle>
                Select technology features
                <%= if is_list(@element["data"]["technology_tags"]) && length(@element["data"]["technology_tags"]) > 0 do %>
                  <.counter>
                    {length(@element["data"]["technology_tags"])}
                  </.counter>
                <% end %>
              </:toggle>
              <.action_list is_multiple_select>
                <%= for {section, values} <- technology_options(@element["data"]["type"]) do %>
                  <.action_list_section_divider>
                    <:title>{Phoenix.Naming.humanize(section)}</:title>
                  </.action_list_section_divider>
                  <%= for value <- values do %>
                    <.action_list_item
                      field={:technology_tags}
                      checked_value={value}
                      is_multiple_select
                      phx-click="update_metadata"
                      phx-value-id={@element["data"]["id"]}
                      phx-value-field="technology_tags"
                      phx-value-checked={value}
                      is_selected={value in @element["data"]["technology_tags"]}
                    >
                      {Phoenix.Naming.humanize(value)}
                    </.action_list_item>
                  <% end %>
                <% end %>
              </.action_list>
            </.action_menu>
            <.checkbox
              name="out-of-scope"
              input_id="data-element-out-of-scope"
              checked={@element["data"]["out_of_scope"] == "true"}
              phx-click="update_metadata"
              phx-value-id={@element["data"]["id"]}
              phx-value-field="out_of_scope"
            >
              <:label>
                Out of scope
              </:label>
            </.checkbox>
          </div>
          <div class="float-left col-8 p-2 pl-4">
            <.box>
              <:header>
                <label>Associated threat statements</label>
                <div class="float-right">
                  <.button
                    is_small
                    phx-click="toggle_link_threat_statement"
                    phx-value-id={@element["data"]["id"]}
                  >
                    <.octicon name="squirrel-16" />
                    <.counter>{length(@element["data"]["linked_threats"])}</.counter>
                  </.button>
                  <.button
                    is_primary
                    is_small
                    phx-click="toggle_generate_threat_statement"
                    phx-value-id={@element["data"]["id"]}
                  >
                    <.octicon name="dependabot-16" />
                  </.button>
                </div>
              </:header>
              <:row :for={threat <- @threats} class="d-flex flex-items-center flex-justify-between">
                <div class="mr-2">
                  <.link
                    href={~p"/workspaces/#{threat.workspace_id}/threats/#{threat.id}"}
                    target="_blank"
                    class="Box-row-link"
                  >
                    {Valentine.Composer.Threat.show_statement(threat)}
                  </.link>
                </div>
                <.button
                  is_danger
                  phx-click="update_metadata"
                  phx-value-id={@element["data"]["id"]}
                  phx-value-value="0"
                  phx-value-field="linked_threats"
                  phx-value-checked={threat.id}
                  data-confirm={gettext("Are you sure?")}
                >
                  <.octicon name="trash-16" />
                </.button>
              </:row>
            </.box>
          </div>
        </div>
      </.box>
    </div>
    """
  end

  defp data_options(type) do
    generic_options = %{
      "customer_data" => ["stores_customer_data", "processes_customer_data"],
      "sensitive_data" => ["stores_sensitive_data", "processes_sensitive_data"],
      "personal_identifiable_information" => [
        "stores_personal_identifiable_information",
        "processes_personal_identifiable_information"
      ]
    }

    specific_options =
      case type do
        "actor" ->
          %{}

        "datastore" ->
          %{
            "logs,_credentials,_encryption" => [
              "stores_logs",
              "stores_credentials",
              "data_is_signed",
              "data_is_encrypted"
            ]
          }

        "edge" ->
          %{}

        "process" ->
          %{"data_exchange_format" => ["json", "xml", "csv", "thirft", "grpc"]}

        "trust_boundary" ->
          %{}

        _ ->
          %{}
      end

    Map.merge(generic_options, specific_options)
  end

  defp security_options(type) do
    generic_options = %{
      "authorization" => ["oauth", "jwt", "saml", "other_authorization", "no_authroization"],
      "authentication" => ["password", "2fa", "mfa", "other_authentication", "no_authentication"],
      "secrets_and_sessions" => ["implements_secrets_management", "implements_session_management"]
    }

    specific_options =
      case type do
        "actor" ->
          %{}

        "datastore" ->
          %{}

        "edge" ->
          %{}

        "process" ->
          %{}

        "trust_boundary" ->
          %{}

        _ ->
          %{}
      end

    Map.merge(generic_options, specific_options)
  end

  defp technology_options(type) do
    generic_options = %{
      "other_features" => ["third party software", "file uploads", "admin_dashboard/console"]
    }

    specific_options =
      case type do
        "actor" ->
          %{"frontend_frameworks" => ["react", "angular", "vue", "svelte", "other_frontend"]}

        "datastore" ->
          %{
            "data storage and querying" => [
              "sql",
              "nosql",
              "data warehouse",
              "data lake",
              "emr",
              "other_storage"
            ]
          }

        "edge" ->
          %{}

        "process" ->
          %{
            "architecture" => ["monolithic", "microservices", "serverless"],
            "language" => [
              "ruby",
              "elixir",
              "python",
              "java",
              "go",
              "javascript",
              "other_language"
            ],
            "os" => ["linux", "windows", "macos", "other"],
            "backend_frameworks" => [
              "rails",
              "phoenix",
              "django",
              "flask",
              "spring",
              "express",
              "other_backend"
            ]
          }

        "trust_boundary" ->
          %{}

        _ ->
          %{}
      end

    Map.merge(generic_options, specific_options)
  end
end
