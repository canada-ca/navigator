# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :valentine, Valentine.Jido,
  max_tasks: 100,
  agent_pools: []

config :valentine, :repo_analysis,
  clone_timeout_ms: 120_000,
  heartbeat_timeout_ms: 300_000,
  repo_access_timeout_ms: 15_000,
  max_repo_files: 2_000,
  max_selected_files: 40,
  max_file_bytes: 20_000,
  max_prompt_bytes: 120_000,
  recovery_interval_ms: 60_000,
  start_recovery: true,
  verify_repo_access: true,
  working_dir:
    System.get_env("REPO_ANALYSIS_WORKING_DIR") ||
      Path.join(System.tmp_dir!(), "valentine_repo_analysis")

config :valentine,
  ecto_repos: [Valentine.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :valentine, ValentineWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ValentineWeb.ErrorHTML, json: ValentineWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Valentine.PubSub,
  live_view: [signing_salt: "a9PbDeU+"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :valentine, Valentine.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  valentine: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    cognito: {Ueberauth.Strategy.Cognito, []},
    google: {Ueberauth.Strategy.Google, []},
    microsoft: {Ueberauth.Strategy.Microsoft, []}
  ]

config :valentine, Valentine.Guardian,
  issuer: "valentine",
  ttl: {7, :days},
  token_ttl: %{
    "api_key" => {365, :days}
  },
  secret_key:
    System.get_env("SECRET_KEY_BASE") ||
      "yllTwLg1HsDDRwYa7O5gaJX4f2TcLPkQ/yKcLZ3H7oY3jBG3TrB8Bf20ei+TQuDv"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
