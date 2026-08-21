defmodule ValentineWeb.WorkspaceLive.Components.ControlCategorizerComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Phoenix.LiveView.AsyncResult
  alias Valentine.ControlCategorizer, as: Categorizer

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:async_result, AsyncResult.loading())
     |> assign(:error, nil)
     |> assign(:suggestion, nil)
     |> assign(:usage, nil)
     |> assign(:request_key, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form phx-value-id={@entity.id} phx-submit="save_tags" phx-target={@myself}>
        <.dialog id="categorization-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@patch)}>
          <:header_title>
            {dialog_title(@entity_type)}
          </:header_title>
          <:body>
            <.spinner :if={@async_result.loading} />
            <div :if={@suggestion} class="mb-3">
              <b>{entity_label(@entity_type)}</b>: {@entity.content}
              <hr />
              <.checkbox
                :for={%{"control" => control, "name" => name, "rational" => rational} <- @suggestion}
                id={control}
                name={"controls[#{control}]"}
                class="mb-2"
              >
                <:label>{control} ({name})</:label>
                <:caption>{rational}</:caption>
              </.checkbox>
            </div>
            <span :if={@error} class="text-red">{@error}</span>
          </:body>
          <:footer>
            <span class="f6">{get_caption(@usage)}</span>
            <hr />
            <.button :if={@suggestion} is_primary type="submit">
              {gettext("Save")}
            </.button>
            <.button :if={@suggestion} phx-click="generate_again" phx-target={@myself}>
              {gettext("Try again")}
            </.button>
            <.button phx-click={cancel_dialog("categorization-modal")}>{gettext("Cancel")}</.button>
          </:footer>
        </.dialog>
      </form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    request_key = {assigns.entity_type, assigns.entity.id}

    socket = assign(socket, assigns)

    if socket.assigns.request_key == request_key do
      {:ok, socket}
    else
      {:ok, start_suggestion(socket)}
    end
  end

  @impl true
  def handle_async(:running_llm, {:ok, {:ok, suggestions}}, socket) do
    async_result = AsyncResult.ok(socket.assigns.async_result, suggestions)

    {:noreply,
     socket
     |> assign(:async_result, async_result)
     |> assign(:error, nil)
     |> assign(:suggestion, suggestions)}
  end

  def handle_async(:running_llm, {:ok, {:error, reason}}, socket) do
    {:noreply, fail_suggestion(socket, reason)}
  end

  def handle_async(:running_llm, {:exit, reason}, socket) do
    {:noreply, fail_suggestion(socket, inspect(reason))}
  end

  @impl true
  def handle_event("generate_again", _params, socket) do
    {:noreply, start_suggestion(socket)}
  end

  def handle_event("save_tags", %{"controls" => controls}, socket) do
    tags = Categorizer.selected_tags(controls)

    case Categorizer.save_tags(socket.assigns.entity_type, socket.assigns.entity, tags) do
      {:ok, entity} ->
        notify_parent({:saved, entity})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, _changeset} ->
        {:noreply, assign(socket, :error, gettext("Unable to save the selected controls"))}
    end
  end

  defp start_suggestion(socket) do
    entity_type = socket.assigns.entity_type
    entity = socket.assigns.entity

    socket
    |> assign(:async_result, AsyncResult.loading())
    |> assign(:error, nil)
    |> assign(:suggestion, nil)
    |> assign(:request_key, {entity_type, entity.id})
    |> start_async(:running_llm, fn -> Categorizer.suggest(entity_type, entity) end)
  end

  defp fail_suggestion(socket, reason) do
    socket
    |> assign(:async_result, AsyncResult.failed(socket.assigns.async_result, reason))
    |> assign(
      :error,
      gettext("Unable to generate control suggestions: %{reason}", reason: reason)
    )
    |> assign(:suggestion, nil)
  end

  defp dialog_title(:assumption),
    do: gettext("Categorize this assumption based on NIST controls")

  defp dialog_title(:mitigation),
    do: gettext("Categorize this mitigation based on NIST controls")

  defp entity_label(:assumption), do: gettext("Assumption")
  defp entity_label(:mitigation), do: gettext("Mitigation")

  defp get_caption(usage) do
    base = gettext("Mistakes are possible. Review output carefully before use.")

    if usage do
      input = usage[:input_tokens] || 0
      output = usage[:output_tokens] || 0
      cost = usage[:total_cost] || Float.round(input * 0.00000015 + output * 0.0000006, 2)

      base <>
        gettext(" Current token usage: (In: %{in}, Out: %{out}, Cost: $%{cost})",
          in: input,
          out: output,
          cost: cost
        )
    else
      base
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
