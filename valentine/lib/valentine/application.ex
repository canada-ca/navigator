defmodule Valentine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ValentineWeb.Telemetry,
      Valentine.Repo,
      {DNSCluster, query: Application.get_env(:valentine, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Valentine.PubSub},
      ValentineWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: Valentine.Finch},
      # Start a worker by calling: Valentine.Worker.start_link(arg)
      # {Valentine.Worker, arg},
      # Start the cache
      {Cachex, [:valentine]},
      # Start to serve requests, typically the last entry
      ValentineWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Valentine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ValentineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
