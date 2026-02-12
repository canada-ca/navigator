defmodule Valentine.MixProject do
  use Mix.Project

  def project do
    [
      app: :valentine,
      version: "0.1.0",
      elixir: "~> 1.18.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Valentine.Application, []},
      extra_applications: [:logger, :runtime_tools, :ueberauth_microsoft]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0", override: true},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:mock, "~> 0.3.0", only: :test},
      {:primer_live, "~> 0.9"},
      {:mdex, "~> 0.2"},
      {:langchain, github: "brainlid/langchain", ref: "315e787c7f4e52c014b52bda0142aa631d3dd28f"},
      {:cachex, "~> 4.0"},
      {:csv, "~> 3.2"},
      {:ueberauth_google, "~> 0.10"},
      {:ueberauth_cognito, "~> 0.3"},
      {:ueberauth_microsoft, "~> 0.23"},
      {:elixlsx, "~> 0.6.0"},
      {:logger_formatter_json, "~> 0.8"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:guardian, "~> 2.3"},
      {:usage_rules, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["cmd npm install --prefix assets --cd assets"],
      "assets.build": ["esbuild valentine"],
      "assets.deploy": ["esbuild valentine", "phx.digest"]
    ]
  end
end
