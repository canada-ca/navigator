defmodule ValentineWeb.PageController do
  use ValentineWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false, auth: auth_active?(), theme: "light")
  end

  defp all_env_vars_present?(vars) do
    Enum.all?(vars, fn var ->
      case System.get_env(var) do
        v when is_binary(v) -> String.length(v) > 0
        _ -> false
      end
    end)
  end

  def auth_active?() do
    cond do
      cognito_auth_active?() -> :cognito
      google_auth_active?() -> :google
      microsoft_auth_active?() -> :microsoft
      true -> false
    end
  end

  defp cognito_auth_active?() do
    all_env_vars_present?([
      "COGNITO_DOMAIN",
      "COGNITO_CLIENT_ID",
      "COGNITO_CLIENT_SECRET",
      "COGNITO_USER_POOL_ID",
      "COGNITO_AWS_REGION"
    ])
  end

  defp google_auth_active?() do
    all_env_vars_present?(["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET"])
  end

  defp microsoft_auth_active?() do
    all_env_vars_present?([
      "MICROSOFT_TENANT_ID",
      "MICROSOFT_CLIENT_ID",
      "MICROSOFT_CLIENT_SECRET"
    ])
  end
end
