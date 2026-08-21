defmodule Valentine.AIProviderTest do
  use ExUnit.Case, async: false

  alias Valentine.AIProvider

  @application_settings [:ai_gateway, :litellm, :model, :openai_api_key, :azure]

  setup do
    original_settings =
      Map.new(@application_settings, fn setting ->
        {setting, Application.fetch_env(:req_llm, setting)}
      end)

    original_max_tokens = System.get_env("REQ_LLM_MAX_TOKENS")

    on_exit(fn ->
      Enum.each(original_settings, fn
        {setting, {:ok, value}} -> Application.put_env(:req_llm, setting, value)
        {setting, :error} -> Application.delete_env(:req_llm, setting)
      end)

      case original_max_tokens do
        nil -> System.delete_env("REQ_LLM_MAX_TOKENS")
        value -> System.put_env("REQ_LLM_MAX_TOKENS", value)
      end
    end)

    Application.put_env(:req_llm, :ai_gateway,
      base_url: "https://llm.example.test/v1/",
      api_key: "sk-gateway"
    )

    System.delete_env("REQ_LLM_MAX_TOKENS")

    :ok
  end

  test "uses a custom OpenAI model input for a gateway alias" do
    Application.put_env(:req_llm, :model, "navigator-analysis")

    assert AIProvider.model_spec("Test") == %{
             provider: :openai,
             id: "navigator-analysis"
           }
  end

  test "uses the default model when the configured alias is blank" do
    Application.put_env(:req_llm, :model, "")

    assert AIProvider.model_spec("Test") == %{
             provider: :openai,
             id: "openai-gpt-5.6-luna"
           }
  end

  test "builds request options for the AI gateway" do
    assert AIProvider.request_opts("Test") == [
             max_tokens: 4096,
             base_url: "https://llm.example.test/v1",
             api_key: "sk-gateway"
           ]
  end

  test "preserves generation overrides without allowing gateway overrides" do
    opts =
      AIProvider.request_opts("Test",
        temperature: 0.2,
        max_tokens: 2048,
        base_url: "https://api.openai.com/v1",
        api_key: "direct-provider-key"
      )

    assert opts[:temperature] == 0.2
    assert opts[:max_tokens] == 2048
    assert opts[:base_url] == "https://llm.example.test/v1"
    assert opts[:api_key] == "sk-gateway"
  end

  test "uses a valid maximum-token environment override" do
    System.put_env("REQ_LLM_MAX_TOKENS", "8192")

    assert AIProvider.request_opts("Test")[:max_tokens] == 8192
  end

  test "rejects a missing gateway URL even when a direct provider key is configured" do
    Application.put_env(:req_llm, :ai_gateway, api_key: "sk-gateway")
    Application.put_env(:req_llm, :openai_api_key, "sk-openai")

    assert_raise ArgumentError, ~r/AI_BASE_URL/, fn ->
      AIProvider.request_opts("Test")
    end
  end

  test "rejects a missing gateway key even when Azure is configured" do
    Application.put_env(:req_llm, :ai_gateway, base_url: "https://llm.example.test/v1")

    Application.put_env(:req_llm, :azure,
      base_url: "https://example.openai.azure.com/openai",
      api_key: "azure-key"
    )

    assert_raise ArgumentError, ~r/AI_API_KEY/, fn ->
      AIProvider.request_opts("Test")
    end
  end
end
