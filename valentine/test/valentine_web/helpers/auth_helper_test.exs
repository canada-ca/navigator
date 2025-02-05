defmodule ValentineWeb.Helpers.AuthHelperTest do
  use ValentineWeb.ConnCase

  alias ValentineWeb.Helpers.AuthHelper

  setup do
    System.put_env("GOOGLE_CLIENT_ID", "")
    System.put_env("GOOGLE_CLIENT_SECRET", "")
    System.put_env("COGNITO_DOMAIN", "")
    System.put_env("COGNITO_CLIENT_ID", "")
    System.put_env("COGNITO_CLIENT_SECRET", "")
    System.put_env("COGNITO_USER_POOL_ID", "")
    System.put_env("COGNITO_AWS_REGION", "")
    System.put_env("MICROSOFT_TENANT_ID", "")
    System.put_env("MICROSOFT_CLIENT_ID", "")
    System.put_env("MICROSOFT_CLIENT_SECRET", "")

    on_exit(fn ->
      System.delete_env("GOOGLE_CLIENT_ID")
      System.delete_env("GOOGLE_CLIENT_SECRET")
      System.delete_env("COGNITO_DOMAIN")
      System.delete_env("COGNITO_CLIENT_ID")
      System.delete_env("COGNITO_CLIENT_SECRET")
      System.delete_env("COGNITO_USER_POOL_ID")
      System.delete_env("COGNITO_AWS_REGION")
      System.delete_env("MICROSOFT_TENANT_ID")
      System.delete_env("MICROSOFT_CLIENT_ID")
      System.delete_env("MICROSOFT_CLIENT_SECRET")
    end)

    socket = %Phoenix.LiveView.Socket{
      private: %{
        lifecycle: %{handle_event: []}
      }
    }

    %{socket: socket}
  end

  describe "init/1" do
    test "returns the default value" do
      assert AuthHelper.init(:default) == :default
    end
  end

  describe "call/2" do
    test "does nothing if GOOGLE env variables are not set", %{conn: conn} do
      System.put_env("GOOGLE_CLIENT_ID", "")
      System.put_env("GOOGLE_CLIENT_SECRET", "")

      resp_conn = AuthHelper.call(conn, :default)

      assert resp_conn.status == nil
      assert resp_conn == conn
    end

    test "halts and redirects to / if user_id is nil", %{conn: conn} do
      System.put_env("GOOGLE_CLIENT_ID", "client_id")
      System.put_env("GOOGLE_CLIENT_SECRET", "client_secret")

      conn =
        conn
        |> Plug.Test.init_test_session(%{"user_id" => nil})

      resp_conn = AuthHelper.call(conn, :default)

      assert resp_conn.status == 302

      assert resp_conn.resp_body ==
               "<html><body>You are being <a href=\"/\">redirected</a>.</body></html>"

      assert resp_conn.resp_headers == [
               {"content-type", "text/html; charset=utf-8"},
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"location", "/"}
             ]
    end

    test "continues if user_id is not nil", %{conn: conn} do
      System.put_env("GOOGLE_CLIENT_ID", "client_id")
      System.put_env("GOOGLE_CLIENT_SECRET", "client_secret")

      conn =
        conn
        |> Plug.Test.init_test_session(%{"user_id" => "user_id"})

      resp_conn = AuthHelper.call(conn, :default)

      assert resp_conn.status == nil
      assert resp_conn == conn
    end
  end

  describe "on_mount/4" do
    test "sets the current_user to a random ID if no auth env variables are not set", %{
      socket: socket
    } do
      {:cont, socket} = AuthHelper.on_mount(:default, %{}, %{}, socket)

      assert socket.assigns[:current_user] != nil
    end

    test "halts and redirects to / if user_id is nil", %{socket: socket} do
      System.put_env("GOOGLE_CLIENT_ID", "client_id")
      System.put_env("GOOGLE_CLIENT_SECRET", "client_secret")

      {:halt, socket} = AuthHelper.on_mount(:default, %{"user_id" => nil}, %{}, socket)

      assert socket.redirected == {:redirect, %{status: 302, to: "/"}}
    end

    test "continues and assigns the user_id to current_user", %{socket: socket} do
      System.put_env("GOOGLE_CLIENT_ID", "client_id")
      System.put_env("GOOGLE_CLIENT_SECRET", "client_secret")

      {:cont, socket} = AuthHelper.on_mount(:default, %{}, %{"user_id" => "user_id"}, socket)

      assert socket.assigns[:current_user] == "user_id"
      assert socket.redirected == nil
    end
  end
end
