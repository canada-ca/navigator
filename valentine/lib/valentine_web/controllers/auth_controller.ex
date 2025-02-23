defmodule ValentineWeb.AuthController do
  use ValentineWeb, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_failure: %Ueberauth.Failure{}}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: %Ueberauth.Auth{} = auth}} = conn, _params) do
    case Valentine.Composer.get_user(auth.info.email) do
      nil ->
        {:ok, _user} = Valentine.Composer.create_user(%{email: auth.info.email})

      user ->
        Valentine.Composer.update_user(user, %{updated_at: DateTime.utc_now()})
    end

    log(:info, auth.info.email, "logged in", auth.provider, "user")

    conn
    |> clear_session()
    |> put_session(:user_id, auth.info.email)
    |> put_session(:live_socket_id, "users_socket:#{auth.info.email}")
    |> redirect(to: ~p"/workspaces")
  end
end
