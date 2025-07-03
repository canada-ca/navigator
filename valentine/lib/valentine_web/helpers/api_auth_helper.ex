defmodule ValentineWeb.Helpers.ApiAuthHelper do
  import Plug.Conn

  alias Valentine.Guardian
  alias Valentine.Composer

  alias ValentineWeb.Helpers.LogHelper

  def init(default), do: default

  def call(conn, _) do
    key =
      conn
      |> get_req_header("authorization")
      |> List.first()

    case key do
      nil ->
        LogHelper.log(
          :info,
          "anonymous",
          "authenticate",
          %{result: "unauthorized", reason: "missing API key"},
          "api"
        )

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
              LogHelper.log(
                :info,
                api_key.id,
                "authenticate",
                %{result: "success", path: conn.request_path},
                "api"
              )

              Composer.update_api_key(api_key, %{last_used: DateTime.utc_now()})
              assign(conn, :api_key, api_key)
            else
              LogHelper.log(
                :info,
                api_key.id,
                "authenticate",
                %{result: "unauthorized", reason: "inactive API key"},
                "api"
              )

              conn
              |> put_status(:unauthorized)
              |> Phoenix.Controller.put_view(ValentineWeb.ErrorJSON)
              |> Phoenix.Controller.render("401.json")
              |> halt
            end

          {:error, reason} ->
            LogHelper.log(
              :info,
              "anonymous",
              "authenticate",
              %{result: "unauthorized", reason: reason},
              "api"
            )

            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.put_view(ValentineWeb.ErrorJSON)
            |> Phoenix.Controller.render("401.json")
            |> halt
        end
    end
  end
end
