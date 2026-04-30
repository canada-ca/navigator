defmodule Valentine.MCP.Dispatcher do
  alias Valentine.MCP.Registry

  @protocol_version "2025-03-26"

  def dispatch("initialize", _params, _api_key) do
    {:ok,
     %{
       protocolVersion: @protocol_version,
       serverInfo: %{name: "navigator", version: "1.0.0"},
       capabilities: %{tools: %{listChanged: false}, resources: %{}}
     }}
  end

  def dispatch("tools/list", _params, _api_key) do
    {:ok, %{tools: Registry.tool_definitions()}}
  end

  def dispatch("tools/call", %{"name" => name, "arguments" => args}, api_key)
      when is_binary(name) and is_map(args) do
    Registry.call_tool(name, args, api_key)
  end

  def dispatch("tools/call", _params, _api_key) do
    {:error, -32602, "Invalid tools/call params"}
  end

  def dispatch("resources/list", _params, _api_key) do
    {:ok, %{resources: []}}
  end

  def dispatch(method, _params, _api_key) do
    {:error, -32601, "Method not found: #{method}"}
  end
end
