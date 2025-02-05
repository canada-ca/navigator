defmodule ValentineWeb.Helpers.AuthHelper do
  def init(default), do: default

  def call(conn, _) do
    if auth_active?() do
      case Plug.Conn.get_session(conn, "user_id") do
        nil ->
          conn
          |> Phoenix.Controller.redirect(to: "/")
          |> Plug.Conn.halt()

        _ ->
          conn
      end
    else
      conn
    end
  end

  def on_mount(:default, _params, session, socket) do
    if auth_active?() do
      case session["user_id"] do
        nil ->
          {:halt, Phoenix.LiveView.redirect(socket, to: "/")}

        user_id ->
          {:cont, Phoenix.Component.assign(socket, :current_user, user_id)}
      end
    else
      user_id =
        Valentine.Cache.get({socket.id, :user_id}) || session["user_id"] || generate_user_id()

      Valentine.Cache.put({socket.id, :user_id}, user_id, expire: :timer.hours(48))

      {:cont, Phoenix.Component.assign(socket, :current_user, user_id)}
    end
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
    cognito_auth_active?() || google_auth_active?() || microsoft_auth_active?()
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

  defp generate_user_id() do
    :crypto.strong_rand_bytes(8) |> Base.encode64() |> Kernel.<>("||") |> String.reverse()
  end
end
