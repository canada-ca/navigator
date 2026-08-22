defmodule ValentineWeb.Helpers.WorkspaceAuthorizationHelper do
  @moduledoc """
  Re-authorizes workspace mutations from current database state.

  Mount-time role assigns are presentation state only. This hook is the common
  server-side boundary for LiveView and LiveComponent events that can change a
  workspace, shared draft, relationship, credential, or job.
  """

  import Phoenix.LiveView, only: [attach_hook: 4, connected?: 1, redirect: 2]

  alias Valentine.Composer.Workspaces

  @read_events ~w(
    change_locale
    change_page
    chat_submit
    clear_filter
    clear_filters
    lv:clear-flash
    close_builder
    close_control_modal
    filter
    fit_view
    search
    select
    select_evidence_filter
    set_tab
    show_context
    toggle_drawer
    toggle_goals
    unselect
    update_chatbot
    update_theme
    view_control_modal
    zoom_in
    zoom_out
  )

  @manage_events ~w(
    cancel_repo_analysis
    flush_api_key
    retry_repo_analysis
    update_permission
  )

  @write_messages [
    :execute_skill,
    :quill_change,
    :quill_save,
    :update_metadata
  ]

  def on_mount(:default, %{"workspace_id" => _workspace_id}, _session, socket) do
    if connected?(socket) do
      {:cont,
       socket
       |> attach_hook(:authorize_workspace_event, :handle_event, &authorize_event/3)
       |> attach_hook(:authorize_workspace_info, :handle_info, &authorize_info/2)}
    else
      {:cont, socket}
    end
  end

  def on_mount(:default, _params, _session, socket), do: {:cont, socket}

  def authorize(socket, capability) when capability in [:read, :write, :manage] do
    workspace_id = socket.assigns[:rbac_workspace_id] || socket.assigns[:workspace_id]
    authorize(socket, workspace_id, capability)
  end

  def authorize(socket, workspace_id, capability) when capability in [:read, :write, :manage] do
    current_user = socket.assigns[:current_user]

    case Workspaces.authorize(workspace_id, current_user, capability) do
      {:ok, workspace} -> {:ok, workspace}
      {:error, _reason} -> {:error, authorization_error(socket, workspace_id, capability)}
    end
  end

  def authorize_component(socket, workspace_id, capability)
      when capability in [:read, :write, :manage] do
    case Workspaces.authorize(workspace_id, socket.assigns[:current_user], capability) do
      {:ok, workspace} ->
        {:ok, workspace}

      {:error, _reason} ->
        message =
          if capability == :manage do
            "Only the workspace owner can perform that action."
          else
            "This workspace is read only for your account."
          end

        {:error, Phoenix.LiveView.put_flash(socket, :error, message)}
    end
  end

  defp authorize_event(event, _params, socket) do
    authorize_hook(socket, event_capability(socket.view, event))
  end

  defp authorize_info(message, socket) do
    case message_capability(message) do
      nil -> {:cont, socket}
      capability -> authorize_hook(socket, capability)
    end
  end

  defp authorize_hook(socket, capability) do
    case authorize(socket, capability) do
      {:ok, _workspace} -> {:cont, socket}
      {:error, socket} -> {:halt, socket}
    end
  end

  defp authorization_error(socket, workspace_id, capability) do
    case Workspaces.authorize(workspace_id, socket.assigns[:current_user], :read) do
      {:ok, _workspace} ->
        message =
          if capability == :manage do
            "Only the workspace owner can perform that action."
          else
            "This workspace is read only for your account."
          end

        Phoenix.LiveView.put_flash(socket, :error, message)

      {:error, _reason} ->
        redirect(socket, to: "/workspaces")
    end
  end

  defp event_capability(ValentineWeb.WorkspaceLive.ApiKey.Index, _event), do: :manage
  defp event_capability(ValentineWeb.WorkspaceLive.Index, _event), do: :manage
  defp event_capability(_view, event) when event in @manage_events, do: :manage
  defp event_capability(_view, event) when event in @read_events, do: :read
  defp event_capability(_view, _event), do: :write

  defp message_capability({message, _payload}) when message in @write_messages, do: :write
  defp message_capability({message, _payload, _extra}) when message in @write_messages, do: :write
  defp message_capability({"update_field", _params}), do: :write
  defp message_capability({_collection, :selected_item, _item}), do: :write
  defp message_capability(_message), do: nil
end
