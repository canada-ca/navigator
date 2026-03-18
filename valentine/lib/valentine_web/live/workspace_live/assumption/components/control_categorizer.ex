defmodule ValentineWeb.WorkspaceLive.Assumption.Components.ControlCategorizer do
  use ValentineWeb, :live_component
  use PrimerLive

  require Logger

  alias Phoenix.LiveView.AsyncResult
  alias Valentine.AIProvider
  alias Valentine.AIResponseNormalizer

  import ReqLLM.Context

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:async_result, AsyncResult.loading())
     |> assign(:error, nil)
     |> assign(:suggestion, nil)
     |> assign(:usage, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form phx-value-id={@assumption.id} phx-submit="save_tags" phx-target={@myself}>
        <.dialog id="categorization-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@patch)}>
          <:header_title>
            {gettext("Categorize this assumption based on NIST controls")}
          </:header_title>
          <:body>
            <.spinner :if={!@suggestion} />
            <div :if={@suggestion} class="mb-3">
              <b>{gettext("Assumption")}</b>: {@assumption.content}
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
  def handle_async(:running_llm, async_fun_result, socket) do
    result = socket.assigns.async_result

    case async_fun_result do
      {:ok, data} ->
        {:noreply, socket |> assign(:async_result, AsyncResult.ok(result, data))}

      {:error, reason} ->
        {:noreply, socket |> assign(:async_result, AsyncResult.failed(result, reason))}
    end
  end

  @impl true
  def handle_event("generate_again", _, socket) do
    send_update(self(), socket.assigns.myself, %{
      id: socket.assigns.id,
      error: nil,
      assumption: socket.assigns.assumption,
      suggestion: nil,
      workspace_id: socket.assigns.workspace_id
    })

    {:noreply, socket |> assign(:suggestion, nil)}
  end

  @impl true
  def handle_event("save_tags", %{"controls" => controls}, socket) do
    tags =
      controls
      |> Enum.filter(fn {_, value} -> value == "true" end)
      |> Enum.map(fn {control, _} -> control end)

    Valentine.Composer.update_assumption(
      socket.assigns.assumption,
      %{tags: (socket.assigns.assumption.tags || []) ++ tags}
    )

    notify_parent({:saved, socket.assigns.assumption})

    {:noreply,
     socket
     |> push_patch(to: socket.assigns.patch)}
  end

  @impl true
  def update(%{chat_complete: data}, socket) do
    case Jason.decode(data.content) do
      {:ok, json} ->
        controls =
          json["controls"]
          |> AIResponseNormalizer.normalize_controls()
          |> Enum.sort_by(& &1["control"])

        {:ok, socket |> assign(:suggestion, controls)}

      _ ->
        {:ok, socket |> assign(:error, "Error decoding response")}
    end
  end

  @impl true
  def update(%{usage_update: usage}, socket) do
    {:ok, socket |> assign(:usage, usage)}
  end

  @impl true
  def update(assigns, socket) do
    lc_pid = self()
    myself = socket.assigns.myself

    {:ok,
     socket
     |> assign(assigns)
     |> start_async(:running_llm, fn ->
       try do
         model_spec = llm_model_spec()

         context =
           ReqLLM.Context.new([system(system_prompt()), user(user_prompt(assigns.assumption))])

         opts = llm_opts()

         obj = ReqLLM.generate_object!(model_spec, context, json_schema(), opts)

         content = Jason.encode!(obj)
         send_update(lc_pid, myself, chat_complete: %{content: content})
         :ok
       rescue
         error ->
           Logger.error("[AssumptionControlCategorizer] Error during control categorization", %{
             error: inspect(error),
             message: Exception.message(error),
             stacktrace: __STACKTRACE__
           })

           {:error, Exception.message(error)}
       end
     end)}
  end

  defp json_schema() do
    %{
      "type" => "object",
      "properties" => %{
        "controls" => %{
          "type" => "array",
          "description" =>
            "A list of up to five NIST controls and their rationales. Always return a JSON array, even when there is only one control.",
          "items" => %{
            "type" => "object",
            "description" => "The control and rational",
            "properties" => %{
              "control" => %{
                "type" => "string",
                "description" => "The control ID as a string, e.g. AC-1, AC-2, SA-11.1 etc."
              },
              "name" => %{
                "type" => "string",
                "description" =>
                  "The name of the control as a string, eg. for AC-2.1 it would be 'Account Management | Automated System Account Management'"
              },
              "rational" => %{
                "type" => "string",
                "description" =>
                  "A short rationale string explaining why this control applies to the assumption"
              }
            },
            "required" => [
              "control",
              "name",
              "rational"
            ],
            "additionalProperties" => false
          }
        }
      },
      "required" => [
        "controls"
      ],
      "additionalProperties" => false
    }
  end

  defp llm_model_spec(), do: AIProvider.model_spec("ControlCategorizer")

  defp llm_opts(), do: AIProvider.request_opts("ControlCategorizer")

  defp system_prompt() do
    """
    You are an expert in NIST security controls. You will be given one or more threat statements from a threat modeling process, an assumption that shapes the model, and any linked mitigations that add context. Your task is to categorize the assumption based on the NIST security controls that are most relevant to validating, governing, or compensating for that assumption.
    """
  end

  defp user_prompt(assumption) do
    """
    Please suggest up to five NIST controls that are most relevant to this assumption. Please also provide a rational why each control applies.

    Threat statements:
    #{if assumption.threats, do: assumption.threats |> Enum.map(&("START:" <> Valentine.Composer.Threat.show_statement(&1) <> "END\n")), else: "No content available"}

    Linked mitigations:
    #{if assumption.mitigations, do: assumption.mitigations |> Enum.map(&(&1.content <> "\n")), else: "No content available"}

    Assumption:
    #{assumption.content}

    Comments about this assumption:
    #{assumption.comments}

    Tags for this assumption (note this may already include NIST controls, please do not repeat):
    #{if assumption.tags, do: assumption.tags |> Enum.join(", ")}

    """
  end

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
