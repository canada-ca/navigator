defmodule ValentineWeb.WorkspaceLive.Mitigation.Components.ControlCategorizer do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Phoenix.LiveView.AsyncResult

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message

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
      <form phx-value-id={@mitigation.id} phx-submit="save_tags" phx-target={@myself}>
        <.dialog id="categorization-modal" is_backdrop is_show is_wide on_cancel={JS.patch(@patch)}>
          <:header_title>
            {gettext("Categorize this mitigation based on NIST controls")}
          </:header_title>
          <:body>
            <.spinner :if={!@suggestion} />
            <div :if={@suggestion} class="mb-3">
              <b>{gettext("Mitigation")}</b>: {@mitigation.content}
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
      mitigation: socket.assigns.mitigation,
      suggestion: nil,
      workspace_id: socket.assigns.workspace_id
    })

    {:noreply, socket |> assign(:suggestion, nil)}
  end

  @impl true
  def handle_event("save_tags", %{"controls" => controls}, socket) do
    tags =
      controls
      |> Enum.filter(fn {_, v} -> v == "true" end)
      |> Enum.map(fn {k, _} -> k end)

    Valentine.Composer.update_mitigation(
      socket.assigns.mitigation,
      %{tags: (socket.assigns.mitigation.tags || []) ++ tags}
    )

    notify_parent({:saved, socket.assigns.mitigation})

    {:noreply,
     socket
     |> push_patch(to: socket.assigns.patch)}
  end

  @impl true
  def update(%{chat_complete: data}, socket) do
    case Jason.decode(data.content) do
      {:ok, json} ->
        # Sort controls

        {:ok, socket |> assign(:suggestion, Enum.sort_by(json["controls"], & &1["control"]))}

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
    chain =
      %{
        llm:
          ChatOpenAI.new!(
            Map.merge(
              %{
                json_response: true,
                json_schema: json_schema(),
                callbacks: [llm_handler(self(), socket.assigns.myself)]
              },
              llm_params()
            )
          ),
        callbacks: [llm_handler(self(), socket.assigns.myself)]
      }
      |> LLMChain.new!()
      |> LLMChain.add_messages([
        Message.new_system!(system_prompt()),
        Message.new_user!(user_prompt(assigns.mitigation))
      ])

    {:ok,
     socket
     |> assign(assigns)
     |> start_async(:running_llm, fn ->
       case LLMChain.run(chain) do
         {:error, %LLMChain{} = _chain, reason} ->
           {:error, reason}

         _ ->
           :ok
       end
     end)}
  end

  defp json_schema() do
    %{
      name: "mitigiation_category_repsonse",
      strict: true,
      schema: %{
        type: "object",
        properties: %{
          controls: %{
            type: "array",
            description: "A list of up to five NIST controls and their rational",
            items: %{
              type: "object",
              description: "The control and rational",
              properties: %{
                control: %{
                  type: "string",
                  description: "The control ID, e.g. AC-1, AC-2, SA-11.1 etc."
                },
                name: %{
                  type: "string",
                  description:
                    "The name of the control, eg. for AC-2.1 it would be 'Account Management | Automated System Account Management'"
                },
                rational: %{
                  type: "string",
                  description: "A rational why this control applies to the mitigation"
                }
              },
              required: [
                "control",
                "name",
                "rational"
              ],
              additionalProperties: false
            }
          }
        },
        required: [
          "controls"
        ],
        additionalProperties: false
      }
    }
  end

  defp llm_handler(lc_pid, myself) do
    %{
      on_message_processed: fn _chain, %Message{} = data ->
        send_update(lc_pid, myself, chat_complete: data)
      end,
      on_llm_token_usage: fn _model, usage ->
        send_update(lc_pid, myself, usage_update: usage)
      end
    }
  end

  defp llm_params() do
    cond do
      Application.get_env(:langchain, :openai_key) ->
        %{
          model: Application.get_env(:langchain, :model),
          max_completion_tokens: 100_000
        }

      Application.get_env(:langchain, :azure_openai_endpoint) ->
        %{
          endpoint: Application.get_env(:langchain, :azure_openai_endpoint),
          api_key: Application.get_env(:langchain, :azure_openai_key),
          max_completion_tokens: 100_000
        }

      true ->
        %{}
    end
  end

  defp system_prompt() do
    """
    You are an expert in NIST security controls. You will be given one or more threat statements that results from a threat modeling process. Additionally you will be given a mitigation whose intent it is to mitigate that specific threat. Your task is to categorize the mitigation based on the NIST security controls.
    """
  end

  defp user_prompt(mitigation) do
    """
    Please suggest up to five NIST controls that the implementation of this mitigation would meet. Please also provide a rational why this control applies.

    Threats statements:
    #{if mitigation.threats, do: mitigation.threats |> Enum.map(&("START:" <> Valentine.Composer.Threat.show_statement(&1) <> "END\n")), else: "No content available"}

    Mitigation:
    #{mitigation.content}

    Comments about this mitigation:application
    #{mitigation.content}

    Tags for this mitigation (note this may already inlcude NIST controls, please do not repeat):
    #{if mitigation.tags, do: mitigation.tags |> Enum.join(", ")}

    """
  end

  defp get_caption(usage) do
    base = gettext("Mistakes are possible. Review output carefully before use.")

    if usage do
      # In cost $0.150 / 1M input tokens
      # Out cost $0.600 / 1M output tokens

      # Cost rounded to cents
      cost = Float.round(usage.input * 0.00000015 + usage.output * 0.0000006, 2)

      base <>
        gettext(" Current token usage: (In: %{in}, Out: %{out}, Cost: $%{cost})",
          in: usage.input,
          out: usage.output,
          cost: cost
        )
    else
      base
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
