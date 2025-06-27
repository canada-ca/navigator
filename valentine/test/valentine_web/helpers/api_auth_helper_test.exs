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
