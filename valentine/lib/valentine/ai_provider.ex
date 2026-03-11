defmodule Valentine.AIProvider do
  @moduledoc false

  require Logger

  @default_model "gpt-4o-mini"
  @default_max_tokens 4096

  def model_spec(component_name) do
    model = model()

    case provider() do
      {:openai, _opts} ->
        "openai:#{model}"

      {:azure, _opts} ->
        "azure:#{model}"

      :none ->
        spec = "openai:#{model}"
        Logger.warning("[#{component_name}] No AI provider configured, falling back to #{spec}")
        spec
    end
  end

  def request_opts(_component_name, extra_opts \\ []) do
    max_tokens = max_tokens()

    opts =
      case provider() do
        {:openai, _opts} ->
          [max_tokens: max_tokens]

        {:azure, azure_opts} ->
          azure_opts
          |> Keyword.take([:api_key, :base_url, :deployment, :api_version])
          |> Kernel.++(max_tokens: max_tokens)

        :none ->
          [max_tokens: max_tokens]
      end
      |> Keyword.merge(extra_opts)

    opts
  end

  defp provider do
    openai_key = Application.get_env(:req_llm, :openai_api_key)
    azure_opts = azure_opts()

    cond do
      present?(openai_key) ->
        {:openai, [api_key: openai_key]}

      present?(azure_opts[:base_url]) ->
        {:azure, azure_opts}

      true ->
        :none
    end
  end

  defp azure_opts do
    azure_config = Keyword.new(Application.get_env(:req_llm, :azure, []))

    normalized_endpoint =
      normalize_azure_endpoint(Application.get_env(:req_llm, :azure_openai_endpoint))

    [
      api_key: azure_config[:api_key] || Application.get_env(:req_llm, :azure_openai_api_key),
      base_url: azure_config[:base_url] || normalized_endpoint.base_url,
      deployment: azure_config[:deployment] || normalized_endpoint.deployment,
      api_version: azure_config[:api_version] || normalized_endpoint.api_version
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
  end

  defp normalize_azure_endpoint(nil), do: %{base_url: nil, deployment: nil, api_version: nil}
  defp normalize_azure_endpoint(""), do: %{base_url: nil, deployment: nil, api_version: nil}

  defp normalize_azure_endpoint(endpoint) do
    uri = URI.parse(endpoint)
    path = uri.path || ""
    query = URI.decode_query(uri.query || "")

    deployment =
      case Regex.run(~r{/deployments/([^/?]+)}, path, capture: :all_but_first) do
        [value] -> value
        _ -> nil
      end

    base_path =
      cond do
        String.contains?(path, "/openai/deployments/") -> "/openai"
        String.starts_with?(path, "/openai") -> "/openai"
        foundry_host?(uri.host) -> ""
        true -> "/openai"
      end

    %{
      base_url: build_base_url(uri, base_path),
      deployment: deployment,
      api_version: query["api-version"]
    }
  end

  defp build_base_url(%URI{scheme: scheme, host: host, port: port}, base_path)
       when is_binary(scheme) and is_binary(host) do
    port_suffix = if port, do: ":#{port}", else: ""
    "#{scheme}://#{host}#{port_suffix}#{base_path}"
  end

  defp build_base_url(_, _), do: nil

  defp foundry_host?(host) when is_binary(host),
    do: String.contains?(host, ".services.ai.azure.com")

  defp foundry_host?(_), do: false

  defp model do
    Application.get_env(:req_llm, :model, @default_model)
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

  defp present?(value) when is_binary(value), do: value != ""
  defp present?(value), do: not is_nil(value)
end
