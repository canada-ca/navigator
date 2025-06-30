defmodule ValentineWeb.Helpers.ApiAuthHelperTest do
  use ValentineWeb.ConnCase

  alias ValentineWeb.Helpers.ApiAuthHelper

  import Valentine.ComposerFixtures

  describe "init/1" do
    test "returns the default value" do
      assert ApiAuthHelper.init(:default) == :default
    end
  end

  describe "call/2" do
    test "returns unauthorized if no authorization header is present", %{conn: conn} do
      resp_conn = ApiAuthHelper.call(conn, :default)

      assert resp_conn.status == 401
    end

    test "returns unauthorized if authorization header is invalid", %{conn: conn} do
      conn = put_req_header(conn, "authorization", "InvalidToken")
      resp_conn = ApiAuthHelper.call(conn, :default)

      assert resp_conn.status == 401
      assert resp_conn.resp_body == "{\"errors\":{\"detail\":\"Unauthorized\"}}"
      assert resp_conn.halted
    end

    test "returns unauthorized if api_key is revoked", %{conn: conn} do
      api_key = api_key_fixture(%{status: :revoked})

      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      resp_conn = ApiAuthHelper.call(conn, :default)
      assert resp_conn.status == 401
      assert resp_conn.resp_body == "{\"errors\":{\"detail\":\"Unauthorized\"}}"
      assert resp_conn.halted
    end

    test "returns unauthorized if api_key is an expired JWT", %{conn: conn} do
      api_key = api_key_fixture(%{status: :active})

      {:ok, token, _claims} =
        Valentine.Guardian.encode_and_sign(api_key, %{}, ttl: {-1, :seconds})

      conn = put_req_header(conn, "authorization", "Bearer #{token}")
      resp_conn = ApiAuthHelper.call(conn, :default)
      assert resp_conn.status == 401
      assert resp_conn.resp_body == "{\"errors\":{\"detail\":\"Unauthorized\"}}"
      assert resp_conn.halted
    end

    test "returns unauthorized if api_key is not signed correctly", %{conn: conn} do
      api_key = api_key_fixture(%{status: :active})

      # Create a token with an incorrect signature
      {:ok, token, _claims} =
        Valentine.Guardian.encode_and_sign(api_key, %{}, ttl: {3600, :seconds})

      # Tamper with the token by inverting the signature
      tampered_token =
        token
        |> String.split(".")
        |> Enum.map(fn part ->
          if part == Enum.at(String.split(token, "."), 2) do
            # Invert the signature part
            String.reverse(part)
          else
            part
          end
        end)
        |> Enum.join(".")

      conn = put_req_header(conn, "authorization", "Bearer #{tampered_token}")
      resp_conn = ApiAuthHelper.call(conn, :default)
      assert resp_conn.status == 401
      assert resp_conn.resp_body == "{\"errors\":{\"detail\":\"Unauthorized\"}}"
      assert resp_conn.halted
    end

    test "assigns api_key if authorization header is valid", %{conn: conn} do
      api_key = api_key_fixture()
      conn = put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      resp_conn = ApiAuthHelper.call(conn, :default)
      assert resp_conn.assigns[:api_key].id == api_key.id

      # Verify that the last_used field is updated
      updated_api_key = Valentine.Composer.get_api_key(api_key.id)
      assert updated_api_key.last_used != nil
    end
  end
end
