defmodule Valentine.AIProvider do
  @moduledoc false

  @default_model "gpt-4o-mini"
  @default_max_tokens 4096

  def model_spec(_component_name), do: %{provider: :openai, id: model()}

  def request_opts(component_name, extra_opts \\ []) do
    litellm_config = Keyword.new(Application.get_env(:req_llm, :litellm, []))

    gateway_opts = [
      base_url:
        litellm_config
        |> Keyword.get(:base_url)
        |> normalize_base_url()
        |> fetch_present!(:base_url, "LITELLM_BASE_URL", component_name),
      api_key:
        litellm_config
        |> Keyword.get(:api_key)
        |> fetch_present!(:api_key, "LITELLM_API_KEY", component_name)
    ]

    [max_tokens: max_tokens()]
    |> Keyword.merge(extra_opts)
    |> Keyword.merge(gateway_opts)
  end

  defp model do
    case Application.get_env(:req_llm, :model, @default_model) do
      model when is_binary(model) and model != "" -> model
      _ -> @default_model
    end
  end

  defp max_tokens do
    case System.get_env("REQ_LLM_MAX_TOKENS") do
      nil ->
        @default_max_tokens

      value ->
        case Integer.parse(value) do
          {tokens, ""} when tokens > 0 -> tokens
          _ -> @default_max_tokens
        end
    end
  end

  defp normalize_base_url(value) when is_binary(value),
    do: value |> String.trim() |> String.trim_trailing("/")

  defp normalize_base_url(value), do: value

  defp fetch_present!(value, _setting, _environment_variable, _component_name)
       when is_binary(value) and value != "",
       do: value

  defp fetch_present!(_value, setting, environment_variable, component_name) do
    raise ArgumentError,
          "[#{component_name}] LiteLLM gateway configuration is incomplete: " <>
            "set #{setting} with #{environment_variable}"
  end
end
