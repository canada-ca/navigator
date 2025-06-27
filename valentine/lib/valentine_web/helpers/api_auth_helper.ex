defmodule ValentineWeb.Helpers.ApiAuthHelper do
  import Plug.Conn

  alias Valentine.Guardian
  alias Valentine.Composer

  def init(default), do: default

  def call(conn, _) do
    key =
      conn
      |> get_req_header("authorization")
      |> List.first()

    case key do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.put_view(ValentineWeb.ErrorJSON)
        |> Phoenix.Controller.render("401.json")
        |> halt

      key ->
        case Guardian.decode_and_verify(String.trim_leading(key, "Bearer ")) do
          {:ok, claims} ->
            {:ok, api_key} = Guardian.resource_from_claims(claims)

            if api_key.status == :active do
              Composer.update_api_key(api_key, %{last_used: DateTime.utc_now()})
              assign(conn, :api_key, api_key)
            else
              conn
              |> put_status(:unauthorized)
              |> Phoenix.Controller.put_view(ValentineWeb.ErrorJSON)
              |> Phoenix.Controller.render("401.json")
              |> halt
            end

          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.put_view(ValentineWeb.ErrorJSON)
            |> Phoenix.Controller.render("401.json")
            |> halt
        end
    end
  end
end
