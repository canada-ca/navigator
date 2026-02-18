defmodule ValentineWeb.WorkspaceLive.Components.ChatComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  alias Valentine.Prompts.PromptRegistry
  alias Phoenix.LiveView.AsyncResult

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message
  alias LangChain.MessageDelta

  def mount(socket) do
    {:ok,
     socket
     |> assign(:chain, build_chain(%{cid: socket.assigns.myself}))
     |> assign(:skills, [])
     |> assign(:usage, nil)
     |> assign(:async_result, AsyncResult.loading())}
  end

  def render(assigns) do
    ~H"""
    <div class="chat_pane">
      <div class="chat_messages" phx-hook="ChatScroll" id="chat-messages">
        <%= if length(@chain.messages) > 0 do %>
          <ul>
            <li
              :for={message <- @chain.messages}
              :if={message.role != :system}
              class="chat_message"
              data-role={message.role}
            >
              <div class="chat_message_role">{role(message.role)}</div>
              {format_msg(message.content, message.role)}
            </li>
            <li :if={@chain.delta} class="chat_message" data-role={@chain.delta.role}>
              <div class="chat_message_role">{role(@chain.delta.role)}</div>
              {format_msg(@chain.delta.content, @chain.delta.role)}
            </li>
          </ul>
        <% else %>
          <.blankslate class="mt-4">
            <:octicon name="dependabot-24" />
            <h3>Ask AI Assistant</h3>
            <p>{tag_line(@active_module, @active_action)}</p>
          </.blankslate>
        <% end %>
      </div>
      <div :if={@skills && length(@skills) > 0} class="skills">
        <div :for={skill <- @skills} class="skill">
          <.button
            type="button"
            phx-click="execute_skill"
            phx-value-id={skill["id"]}
            phx-target={@myself}
          >
            {skill["description"]}
          </.button>
        </div>
      </div>
      <div class="chat_input_container">
        <.textarea
          placeholder="Ask AI Assistant"
          is_full_width
          rows="3"
          caption={get_caption(@usage)}
          is_form_control
          phx-hook="EnterSubmitHook"
          id="chat_input"
        />
      </div>
    </div>
    """
  end

  def update(%{chat_complete: data}, socket) do
    skills =
      case Jason.decode!(data.content) do
        %{"skills" => skills} -> skills
        _ -> []
      end

    {:ok,
     socket
     |> assign(:skills, skills)}
  end

  def update(%{chat_response: data}, socket) do
    chain =
      socket.assigns.chain
      |> LLMChain.apply_delta(data)

    %{workspace_id: workspace_id, current_user: user_id} = socket.assigns

    Valentine.Cache.put({workspace_id, user_id, :chatbot_history}, chain.messages,
      expire: :timer.hours(24)
    )

    {:ok,
     socket
     |> assign(chain: chain)}
  end

  def update(%{skill_result: %{id: id, status: status, msg: msg}}, socket) do
    chain =
      socket.assigns.chain
      |> LLMChain.add_messages([
        Message.new_system!(
          "The user clicked the button with id: #{id} and the result was: #{status} - #{msg}"
        )
      ])

    {:ok,
     socket
     |> assign(chain: chain)}
  end

  def update(%{usage_update: usage}, socket) do
    {:ok,
     socket
     |> assign(usage: usage)}
  end

  def update(assigns, socket) do
    %{workspace_id: workspace_id, current_user: user_id} = assigns
    cached_messages = Valentine.Cache.get({workspace_id, user_id, :chatbot_history}) || []

    {:ok,
     socket
     |> assign(
       :chain,
       build_chain(%{
         stream: true,
         stream_options: %{include_usage: true},
         json_response: true,
         json_schema:
           PromptRegistry.get_schema(
             assigns.active_module,
             assigns.active_action
           ),
         callbacks: [llm_handler(self(), socket.assigns.myself)],
         cid: socket.assigns.myself
       })
       |> LLMChain.add_messages(cached_messages)
     )
     |> assign(assigns)}
  end

  def handle_async(:running_llm, async_fun_result, socket) do
    result = socket.assigns.async_result

    case async_fun_result do
      {:ok, data} ->
        {:noreply, socket |> assign(:async_result, AsyncResult.ok(result, data))}

      {:error, reason} ->
        {:noreply, socket |> assign(:async_result, AsyncResult.failed(result, reason))}
    end
  end

  def handle_event("chat_submit", %{"value" => "/clear"}, socket) do
    %{workspace_id: workspace_id, current_user: user_id} = socket.assigns

    chain =
      build_chain(%{
        stream: true,
        stream_options: %{include_usage: true},
        json_response: true,
        json_schema:
          PromptRegistry.get_schema(
            socket.assigns.active_module,
            socket.assigns.active_action
          ),
        callbacks: [llm_handler(self(), socket.assigns.myself)],
        cid: socket.assigns.myself
      })

    # Clear from cache (store empty messages list)
    Valentine.Cache.put({workspace_id, user_id, :chatbot_history}, [], expire: :timer.hours(24))

    {:noreply,
     socket
     |> assign(chain: chain)}
  end

  def handle_event("chat_submit", %{"value" => value}, socket) do
    %{
      workspace_id: workspace_id,
      current_user: user_id,
      active_module: active_module,
      active_action: active_action
    } = socket.assigns

    chain =
      socket.assigns.chain
      |> LLMChain.add_messages([
        Message.new_system!(
          PromptRegistry.get_system_prompt(active_module, active_action, workspace_id)
        ),
        Message.new_user!(value)
      ])

    Valentine.Cache.put({workspace_id, user_id, :chatbot_history}, chain.messages,
      expire: :timer.hours(24)
    )

    {:noreply,
     socket
     |> assign(chain: chain)
     |> run_chain()}
  end

  def handle_event("execute_skill", %{"id" => skill_id}, socket) do
    skill = socket.assigns.skills |> Enum.find(&(&1["id"] == skill_id))

    socket = socket |> assign(:skills, [])

    if skill do
      send(self(), {:execute_skill, skill})
      {:noreply, socket}
    else
      {:noreply, socket |> put_flash!(:error, "Skill not found")}
    end
  end

  def run_chain(socket) do
    chain = socket.assigns.chain

    socket
    |> assign(:async_result, AsyncResult.loading())
    |> start_async(:running_llm, fn ->
      case LLMChain.run(chain) do
        {:error, %LLMChain{} = _chain, reason} ->
          {:error, reason}

        _ ->
          :ok
      end
    end)
  end

  defp build_chain(params) do
    %{
      llm: ChatOpenAI.new!(Map.merge(params, llm_params())),
      callbacks: [llm_handler(self(), params.cid)]
    }
    |> LLMChain.new!()
  end

  defp extract(input) do
    case :binary.match(input, "\"content\":\"") do
      {pos, len} ->
        start_pos = pos + len
        content_portion = binary_part(input, start_pos, byte_size(input) - start_pos)
        extract_until_unescaped_quote(content_portion)

      :nomatch ->
        ""
    end
  end

  defp extract_until_unescaped_quote(<<>>) do
    ""
  end

  defp extract_until_unescaped_quote(<<"\\\"", rest::binary>>) do
    "\\\"" <> extract_until_unescaped_quote(rest)
  end

  defp extract_until_unescaped_quote(<<"\"", _rest::binary>>) do
    ""
  end

  defp extract_until_unescaped_quote(<<char::utf8, rest::binary>>) do
    <<char::utf8>> <> extract_until_unescaped_quote(rest)
  end

  defp get_caption(usage) do
    base = "Mistakes are possible. Review output carefully before use."

    if usage do
      # In cost $0.150 / 1M input tokens
      # Out cost $0.600 / 1M output tokens

      # Cost rounded to cents
      cost = Float.round(usage.input * 0.00000015 + usage.output * 0.0000006, 2)

      base <> " Current token usage: (In: #{usage.input}, Out: #{usage.output}, Cost: $#{cost})"
    else
      base
    end
  end

  defp format_msg(content, :user), do: content

  defp format_msg(content, _) do
    case Jason.decode(content) do
      {:ok, %{"content" => content}} ->
        content |> MDEx.to_html!() |> Phoenix.HTML.raw()

      _ ->
        content
        |> extract()
        |> Phoenix.HTML.raw()
    end
  end

  defp llm_handler(lc_pid, myself) do
    %{
      on_llm_new_delta: fn _model, %MessageDelta{} = data ->
        send_update(lc_pid, myself, chat_response: data)
      end,
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

  defp tag_line(module, action) do
    PromptRegistry.get_tag_line(module, action)
  end

  defp role(:assistant), do: "AI Assistant"
  defp role(:user), do: "You"
  defp role(role), do: role
end
