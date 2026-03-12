defmodule ValentineWeb.WorkspaceLive.GitHubImportComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  import Phoenix.HTML.Form, only: [input_value: 2]

  alias Ecto.Changeset
  alias Valentine.RepoAnalysis

  @form_types %{
    github_url: :string,
    name: :string,
    cloud_profile: :string,
    cloud_profile_type: :string
  }

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@form}
        id="github-import-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.dialog
          id="github-import-modal"
          is_backdrop
          is_show
          is_wide
          on_cancel={JS.patch(@patch)}
        >
          <:header_title>
            {gettext("Import from GitHub")}
          </:header_title>
          <:body>
            <.text_input
              form={f}
              field={:github_url}
              form_control={%{label: gettext("Public GitHub URL")}}
              is_full_width
              is_form_control
            />

            <.text_input
              form={f}
              field={:name}
              form_control={%{label: gettext("Workspace name")}}
              is_full_width
              is_form_control
            />

            <.select
              form={f}
              name="import[cloud_profile]"
              options={[
                [key: gettext("None selected"), value: ""],
                [key: gettext("CCCS Low Profile for Cloud"), value: "CCCS Low Profile for Cloud"],
                [key: gettext("CCCS Medium Profile for Cloud"), value: "CCCS Medium Profile for Cloud"]
              ]}
              selected={input_value(f, :cloud_profile)}
              is_form_control
            />

            <.select
              form={f}
              name="import[cloud_profile_type]"
              options={[
                [key: gettext("None selected"), value: ""],
                [key: gettext("CSP Full Stack"), value: "CSP Full Stack"],
                [key: gettext("CSP Stacked PaaS"), value: "CSP Stacked PaaS"],
                [key: gettext("CSP Stacked SaaS"), value: "CSP Stacked SaaS"],
                [key: gettext("Client IaaS / PaaS"), value: "Client IaaS / PaaS"],
                [key: gettext("Client SaaS"), value: "Client SaaS"]
              ]}
              selected={input_value(f, :cloud_profile_type)}
              is_form_control
            />

            <div :if={@error} class="FormControl-inlineValidation FormControl-inlineValidation--error">
              {@error}
            </div>
          </:body>
          <:footer>
            <.button is_primary is_submit phx-disable-with={gettext("Starting...")}>
              {gettext("Start import")}
            </.button>
            <.button phx-click={cancel_dialog("github-import-modal")}>
              {gettext("Cancel")}
            </.button>
          </:footer>
        </.dialog>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    params = default_params()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:params, params)
     |> assign(:form, to_form(change_import(params), as: :import))
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("validate", %{"import" => params}, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:form, to_form(change_import(params), as: :import))}
  end

  @impl true
  def handle_event("save", %{"import" => params}, socket) do
    case RepoAnalysis.create_import(socket.assigns.current_user, params) do
      {:ok, %{workspace: workspace}} ->
        notify_parent({:saved, workspace})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Repository analysis started"))
         |> push_navigate(to: socket.assigns.redirect_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:params, params)
         |> assign(:form, to_form(change_import(params), as: :import))
         |> assign(:error, format_changeset_error(changeset))}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:params, params)
         |> assign(:form, to_form(change_import(params), as: :import))
         |> assign(:error, format_reason(reason))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp change_import(params) do
    {%{}, @form_types}
    |> Changeset.cast(params, Map.keys(@form_types))
  end

  defp default_params do
    %{
      "github_url" => "",
      "name" => "",
      "cloud_profile" => "",
      "cloud_profile_type" => ""
    }
  end

  defp format_changeset_error(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field} #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)
end
