defmodule ValentineWeb.Api.MCPController do
  use ValentineWeb, :controller

  alias Valentine.MCP.Dispatcher

  def stream_not_supported(conn, _params) do
    send_resp(conn, :method_not_allowed, "")
  end

  def handle(conn, %{"_json" => messages}) when is_list(messages) do
    handle(conn, messages)
  end

  def handle(conn, messages) when is_list(messages) do
    api_key = conn.assigns[:api_key]

    responses =
      messages
      |> Enum.map(&response_for(&1, api_key))
      |> Enum.reject(&is_nil/1)

    if responses == [] do
      send_resp(conn, :accepted, "")
    else
      json(conn, responses)
    end
  end

  def handle(conn, %{} = message) do
    api_key = conn.assigns[:api_key]

    case response_for(message, api_key) do
      nil -> send_resp(conn, :accepted, "")
      response -> json(conn, response)
    end
  end

  def handle(conn, _params) do
    json(conn, error_response(nil, -32600, "Invalid Request"))
  end

  defp response_for(%{"jsonrpc" => "2.0", "method" => method} = message, api_key) do
    if Map.has_key?(message, "id") do
      id = Map.get(message, "id")
      params = Map.get(message, "params", %{})

      case Dispatcher.dispatch(method, params, api_key) do
        {:ok, data} -> %{jsonrpc: "2.0", id: id, result: data}
        {:error, code, message} -> error_response(id, code, message)
      end
    end
  rescue
    _error -> error_response(Map.get(message, "id"), -32603, "Internal error")
  end

  defp response_for(%{"jsonrpc" => "2.0"}, _api_key), do: nil

  defp response_for(message, _api_key) do
    if is_map(message) && Map.has_key?(message, "id") do
      error_response(Map.get(message, "id"), -32600, "Invalid Request")
    end
  end

  defp error_response(id, code, message) do
    %{jsonrpc: "2.0", id: id, error: %{code: code, message: message}}
  end
end
