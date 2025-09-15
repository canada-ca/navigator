import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :valentine, Valentine.Repo,
  url:
    (System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost") <>
      "/valentine_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :valentine, ValentineWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "TnTYuur9uww/9Ff4AGG6lMxhGeQikthVNKzskqJ6tT+rXc5KX43yQAdGFRGux4Ra",
  server: false

# In test we don't send emails
config :valentine, Valentine.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Set the CI environment to true
System.put_env("CI", "true")
