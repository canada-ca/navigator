defmodule ValentineWeb.SessionController do
  use ValentineWeb, :controller

  def create(conn, %{"chatbot" => chatbot}), do: store_string(conn, :chatbot, chatbot)
  def create(conn, %{"locale" => locale}), do: store_string(conn, :locale, locale)
  def create(conn, %{"theme" => theme}), do: store_string(conn, :theme, theme)
  def create(conn, _params), do: conn |> send_resp(400, "")

  defp store_string(conn, key, value) do
    conn
    |> put_session(key, value)
    |> send_resp(200, "")
  end

  def logout(conn, _params) do
    user_id = get_session(conn, :user_id)

    log(:info, user_id, "logged out", user_id, "user")

    ValentineWeb.Endpoint.broadcast("users_socket:#{user_id}", "disconnect", %{})

    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
