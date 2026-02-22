defmodule ValentineWeb.WorkspaceLive.Evidence.Show do
  use ValentineWeb, :live_view
  use PrimerLive

  alias Valentine.Composer
  alias Valentine.Composer.Evidence

  @impl true
  def mount(%{"workspace_id" => workspace_id} = _params, _session, socket) do
    workspace = get_workspace(workspace_id)

    {:ok,
     socket
     |> assign(:workspace_id, workspace_id)
     |> assign(:workspace, workspace)
     |> assign(:errors, nil)
     |> assign(:changes, %{})
     |> assign(:content_raw, "")
     |> assign(:tag_input, "")
     |> assign(:nist_control_input, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("Create Evidence"))
    |> assign(:evidence, %Evidence{})
    |> assign(:changes, %{workspace_id: socket.assigns.workspace_id, tags: [], nist_controls: [], evidence_type: :json_data})
    |> assign(:content_raw, "")
  end

  defp apply_action(socket, :edit, %{"id" => id} = _params) do
    evidence = Composer.get_evidence!(id)

    socket
    |> assign(:page_title, gettext("Edit Evidence"))
    |> assign(:evidence, evidence)
    |> assign(:changes, Map.from_struct(evidence))
    |> assign(:content_raw, encode_content(evidence.content))
  end

  @impl true
  def handle_event("update_field", %{"_target" => [field]} = params, socket) do
    value = Map.get(params, field)

    case field do
      "content_raw" ->
        {:noreply, assign(socket, :content_raw, value || "")}

      "evidence_type" ->
        evidence_type = normalize_evidence_type(value)
        changes = Map.put(socket.assigns.changes, :evidence_type, evidence_type)
        {:noreply, assign(socket, :changes, changes)}

      _ ->
        changes =
          socket.assigns.changes
          |> Map.put(String.to_existing_atom(field), value)

        {:noreply, assign(socket, :changes, changes)}
    end
  end

  @impl true
  def handle_event("set_tag_input", %{"value" => value, "field" => field}, socket) do
    socket =
      case field do
        "tags" -> assign(socket, :tag_input, value)
        "nist_controls" -> assign(socket, :nist_control_input, value)
        _ -> socket
      end

    {:noreply, socket}
  end

  def handle_event("set_tag_input", %{"value" => value}, socket) do
    {:noreply, assign(socket, :tag_input, value)}
  end

  @impl true
  def handle_event("add_tag", %{"field" => field}, socket) do
    {input_value, input_key} =
      case field do
        "tags" -> {socket.assigns.tag_input, :tag_input}
        "nist_controls" -> {socket.assigns.nist_control_input, :nist_control_input}
        _ -> {"", nil}
      end

    if input_key && byte_size(input_value) > 0 do
      field_key = tag_field_from_param(field)
      current_values = Map.get(socket.assigns.changes, field_key) || []

      if input_value in current_values do
        {:noreply, socket}
      else
        updated_values = current_values ++ [input_value]

        {:noreply,
         socket
         |> assign(:changes, Map.put(socket.assigns.changes, field_key, updated_values))
         |> assign(input_key, "")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_tag", %{"field" => field, "tag" => tag}, socket) do
    field_key = tag_field_from_param(field)
    current_values = Map.get(socket.assigns.changes, field_key) || []
    updated_values = List.delete(current_values, tag)

    {:noreply, assign(socket, :changes, Map.put(socket.assigns.changes, field_key, updated_values))}
  end

  @impl true
  def handle_event("save", _params, socket) do
    if socket.assigns.evidence.id do
      update_existing_evidence(socket)
    else
      create_new_evidence(socket)
    end
  end

  defp create_new_evidence(socket) do
    with {:ok, attrs} <- build_evidence_attrs(socket),
         {:ok, evidence} <- Composer.create_evidence_with_linking(attrs, %{}) do
      log(
        :info,
        socket.assigns.current_user,
        "create",
        %{evidence: evidence.id, workspace: evidence.workspace_id},
        "evidence"
      )

      {:noreply,
       socket
       |> put_flash(:info, gettext("Evidence created successfully"))
       |> push_navigate(to: ~p"/workspaces/#{evidence.workspace_id}/evidence/#{evidence.id}")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :errors, changeset.errors)}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, :errors, errors)}
    end
  end

  defp update_existing_evidence(socket) do
    with {:ok, attrs} <- build_evidence_attrs(socket),
         {:ok, evidence} <- Composer.update_evidence(socket.assigns.evidence, attrs) do
      Composer.apply_evidence_linking(evidence, %{})

      log(
        :info,
        socket.assigns.current_user,
        "update",
        %{evidence: evidence.id, workspace: evidence.workspace_id},
        "evidence"
      )

      {:noreply,
       socket
       |> put_flash(:info, gettext("Evidence updated successfully"))
       |> push_navigate(to: ~p"/workspaces/#{evidence.workspace_id}/evidence/#{evidence.id}")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :errors, changeset.errors)}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, :errors, errors)}
    end
  end

  defp build_evidence_attrs(socket) do
    changes = socket.assigns.changes
    evidence_type = normalize_evidence_type(changes[:evidence_type])

    attrs = %{
      workspace_id: socket.assigns.workspace_id,
      name: blank_to_nil(changes[:name]),
      description: blank_to_nil(changes[:description]),
      evidence_type: evidence_type,
      blob_store_url: blank_to_nil(changes[:blob_store_url]),
      tags: changes[:tags] || [],
      nist_controls: changes[:nist_controls] || []
    }

    case evidence_type do
      :json_data ->
        case parse_json_content(socket.assigns.content_raw) do
          {:ok, content} -> {:ok, Map.put(attrs, :content, content)}
          {:error, errors} -> {:error, errors}
        end

      :blob_store_link ->
        {:ok, Map.put(attrs, :content, nil)}

      _ ->
        {:ok, attrs}
    end
  end

  defp parse_json_content(content_raw) do
    trimmed = content_raw |> to_string() |> String.trim()

    if trimmed == "" do
      {:ok, nil}
    else
      case Jason.decode(trimmed) do
        {:ok, content} -> {:ok, content}
        {:error, _} -> {:error, [{:content, {"is not valid JSON", []}}]}
      end
    end
  end

  defp encode_content(nil), do: ""
  defp encode_content(content), do: Jason.encode!(content, pretty: true)

  defp normalize_evidence_type(nil), do: nil
  defp normalize_evidence_type(""), do: nil
  defp normalize_evidence_type(value) when is_atom(value), do: value

  defp normalize_evidence_type(value) when is_binary(value) do
    value
    |> Phoenix.Naming.underscore()
    |> String.to_existing_atom()
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp tag_field_from_param("tags"), do: :tags
  defp tag_field_from_param("nist_controls"), do: :nist_controls
  defp tag_field_from_param(_), do: :tags

  defp get_workspace(id) do
    Composer.get_workspace!(id)
  end
end
