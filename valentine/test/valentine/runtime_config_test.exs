defmodule Valentine.RuntimeConfigTest do
  use ExUnit.Case, async: false

  @runtime_config Path.expand("../../config/runtime.exs", __DIR__)
  @managed_environment ~w(DATABASE_URL SECRET_KEY_BASE GUARDIAN_SECRET_KEY)

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

  defp read_production_config do
    Config.Reader.read!(@runtime_config, env: :prod)
  end
end
