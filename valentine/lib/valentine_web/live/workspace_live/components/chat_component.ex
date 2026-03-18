defmodule ValentineWeb.WorkspaceLive.Components.ChatComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  require Logger

  alias Valentine.AIProvider
  alias Valentine.Prompts.PromptRegistry
  alias Phoenix.LiveView.AsyncResult

  import ReqLLM.Context

  def mount(socket) do
    {:ok,
     socket
     |> assign(:messages, [])
     |> assign(:delta, nil)
     |> assign(:usage, nil)
     |> assign(:async_result, AsyncResult.loading())}
  end

  def render(assigns) do
    ~H"""
    <div class="chat_pane">
      <div class="chat_messages" phx-hook="ChatScroll" id="chat-messages">
        <%= if length(@messages) > 0 || @delta do %>
          <ul>
            <li
              :for={message <- @messages}
              :if={message.role != :system}
              class="chat_message"
              data-role={message.role}
            >
              <div class="chat_message_role">{role(message.role)}</div>
              {format_msg(message.content, message.role)}
            </li>
            <li :if={@delta && @delta != ""} class="chat_message" data-role={:assistant}>
              <div class="chat_message_role">{role(:assistant)}</div>
              {format_msg(@delta, :assistant)}
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
    completed_message = %{role: :assistant, content: data.content}
    messages = socket.assigns.messages ++ [completed_message]

    %{workspace_id: workspace_id, current_user: user_id} = socket.assigns

    Valentine.Cache.put({workspace_id, user_id, :chatbot_history}, messages,
      expire: :timer.hours(24)
    )

    {:ok,
     socket
     |> assign(:messages, messages)
     |> assign(:delta, nil)}
  end

  def update(%{chat_response: chunk}, socket) do
    delta = (socket.assigns.delta || "") <> chunk

    {:ok,
     socket
     |> assign(:delta, delta)}
  end

  def update(%{skill_result: %{id: id, status: status, msg: msg}}, socket) do
    new_msg = %{
      role: :system,
      content: "The user clicked the button with id: #{id} and the result was: #{status} - #{msg}"
    }

    messages = socket.assigns.messages ++ [new_msg]

    {:ok,
     socket
     |> assign(:messages, messages)}
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
     |> assign(:messages, cached_messages)
     |> assign(:delta, nil)
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

    Valentine.Cache.put({workspace_id, user_id, :chatbot_history}, [], expire: :timer.hours(24))

    {:noreply,
     socket
     |> assign(:messages, [])
     |> assign(:delta, nil)}
  end

  def handle_event("chat_submit", %{"value" => value}, socket) do
    %{
      workspace_id: workspace_id,
      current_user: user_id,
      active_module: active_module,
      active_action: active_action
    } = socket.assigns

    system_message = %{
      role: :system,
      content: PromptRegistry.get_system_prompt(active_module, active_action, workspace_id)
    }

    messages =
      socket.assigns.messages
      |> with_system_message(system_message)
      |> Kernel.++([%{role: :user, content: value}])

    Valentine.Cache.put({workspace_id, user_id, :chatbot_history}, messages,
      expire: :timer.hours(24)
    )

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> run_chain()}
  end

  def run_chain(socket) do
    lc_pid = self()
    myself = socket.assigns.myself
    messages = socket.assigns.messages

    socket
    |> assign(:async_result, AsyncResult.loading())
    |> start_async(:running_llm, fn ->
      try do
        model_spec = llm_model_spec()
        context = build_context(messages)
        opts = llm_opts()

        result = ReqLLM.generate_text(model_spec, context, opts)

        case result do
          {:ok, response} ->
            content = chat_completion_content(response)
            send_update(lc_pid, myself, chat_complete: %{content: content})

            usage = ReqLLM.Response.usage(response)

            if usage do
              send_update(lc_pid, myself, usage_update: usage)
            end

            :ok

          {:error, reason} ->
            Logger.error(
              "[ChatComponent] ReqLLM.generate_text failed reason=#{inspect(reason)} model_spec=#{inspect(model_spec)} opts=#{inspect(Keyword.drop(opts, [:api_key]))}"
            )

            {:error, reason}
        end
      rescue
        e ->
          Logger.error("[ChatComponent] Unexpected error in run_chain", %{
            error: inspect(e),
            stacktrace: __STACKTRACE__
          })

          {:error, Exception.message(e)}
      end
    end)
  end

  defp build_context(messages) do
    msgs =
      messages
      |> normalize_context_messages()
      |> Enum.map(fn %{role: role, content: content} ->
        case role do
          :system -> system(content)
          :user -> user(content)
          :assistant -> assistant(content)
          _ -> user(content)
        end
      end)

    ReqLLM.Context.new(msgs)
  end

  defp chat_completion_content(response) do
    ReqLLM.Response.text(response) || ""
  end

  defp with_system_message(messages, system_message) do
    non_system_messages = Enum.reject(messages, &(&1.role == :system))
    [system_message | non_system_messages]
  end

  defp normalize_context_messages(messages) do
    {system_messages, non_system_messages} = Enum.split_with(messages, &(&1.role == :system))

    case system_messages do
      [] ->
        non_system_messages

      [first | rest] ->
        extra_system_messages =
          Enum.map(rest, fn message ->
            %{role: :user, content: "Context event: #{message.content}"}
          end)

        [first | non_system_messages ++ extra_system_messages]
    end
  end

  defp get_caption(usage) do
    base = "Mistakes are possible. Review output carefully before use."

    if usage do
      input = usage[:input_tokens] || 0
      output = usage[:output_tokens] || 0
      cost = usage[:total_cost] || Float.round(input * 0.00000015 + output * 0.0000006, 2)

      base <> " Current token usage: (In: #{input}, Out: #{output}, Cost: $#{cost})"
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
        content |> MDEx.to_html!() |> Phoenix.HTML.raw()
    end
  end

  defp llm_model_spec(), do: AIProvider.model_spec("ChatComponent")

  defp llm_opts(), do: AIProvider.request_opts("ChatComponent")

  defp tag_line(module, action) do
    PromptRegistry.get_tag_line(module, action)
  end

  defp role(:assistant), do: "AI Assistant"
  defp role(:user), do: "You"
  defp role(role), do: role
end
