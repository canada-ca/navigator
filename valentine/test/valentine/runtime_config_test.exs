defmodule Valentine.RuntimeConfigTest do
  use ExUnit.Case, async: false

  @runtime_config Path.expand("../../config/runtime.exs", __DIR__)
  @managed_environment ~w(
    DATABASE_URL
    SECRET_KEY_BASE
    GUARDIAN_SECRET_KEY
    LITELLM_BASE_URL
    LITELLM_API_KEY
    LITELLM_MODEL
    OPENAI_API_KEY
    OPENAI_MODEL
    AZURE_OPENAI_KEY
    AZURE_OPENAI_ENDPOINT
    AZURE_OPENAI_BASE_URL
    AZURE_OPENAI_DEPLOYMENT
    AZURE_OPENAI_API_VERSION
  )

  setup do
    original_environment =
      Map.new(@managed_environment, fn variable -> {variable, System.get_env(variable)} end)

    System.put_env("DATABASE_URL", "ecto://postgres:postgres@localhost/valentine_test")
    System.put_env("SECRET_KEY_BASE", String.duplicate("s", 64))

    on_exit(fn ->
      Enum.each(original_environment, fn
        {variable, nil} -> System.delete_env(variable)
        {variable, value} -> System.put_env(variable, value)
      end)
    end)

    :ok
  end

  test "production refuses to start without a JWT signing key" do
    System.delete_env("GUARDIAN_SECRET_KEY")

    assert_raise RuntimeError, ~r/GUARDIAN_SECRET_KEY is missing/, fn ->
      read_production_config()
    end
  end

  test "production refuses a short JWT signing key" do
    System.put_env("GUARDIAN_SECRET_KEY", "public-or-guessable")

    assert_raise RuntimeError, ~r/GUARDIAN_SECRET_KEY must contain at least 64 bytes/, fn ->
      read_production_config()
    end
  end

  test "production configures Guardian with the runtime JWT signing key" do
    guardian_secret_key = String.duplicate("g", 64)
    System.put_env("GUARDIAN_SECRET_KEY", guardian_secret_key)

    guardian_config =
      @runtime_config
      |> Config.Reader.read!(env: :prod)
      |> Keyword.fetch!(:valentine)
      |> Keyword.fetch!(Valentine.Guardian)

    assert guardian_config[:secret_key] == guardian_secret_key
  end

  test "configures ReqLLM exclusively for the LiteLLM gateway" do
    System.put_env("LITELLM_BASE_URL", "https://llm.example.test/v1")
    System.put_env("LITELLM_API_KEY", "sk-litellm")
    System.put_env("LITELLM_MODEL", "navigator-analysis")
    System.put_env("OPENAI_API_KEY", "sk-openai")
    System.put_env("OPENAI_MODEL", "gpt-4o")
    System.put_env("AZURE_OPENAI_KEY", "azure-key")
    System.put_env("AZURE_OPENAI_ENDPOINT", "https://example.openai.azure.com")

    req_llm_config =
      @runtime_config
      |> Config.Reader.read!(env: :test)
      |> Keyword.fetch!(:req_llm)

    assert req_llm_config[:litellm] == [
             base_url: "https://llm.example.test/v1",
             api_key: "sk-litellm"
           ]

    assert req_llm_config[:model] == "navigator-analysis"
    refute Keyword.has_key?(req_llm_config, :openai_api_key)
    refute Keyword.has_key?(req_llm_config, :azure_openai_api_key)
    refute Keyword.has_key?(req_llm_config, :azure_openai_endpoint)
    refute Keyword.has_key?(req_llm_config, :azure)
  end

  defp read_production_config do
    Config.Reader.read!(@runtime_config, env: :prod)
  end
end
