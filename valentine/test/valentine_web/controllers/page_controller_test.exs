defmodule ValentineWeb.PageControllerTest do
  use ValentineWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Security by Design, Not by Chance."
  end

  test "GET / with cognito auth shows a cognito auth login button", %{conn: conn} do
    System.put_env("COGNITO_DOMAIN", "domain")
    System.put_env("COGNITO_CLIENT_ID", "client_id")
    System.put_env("COGNITO_CLIENT_SECRET", "client_secret")
    System.put_env("COGNITO_USER_POOL_ID", "user_pool_id")
    System.put_env("COGNITO_AWS_REGION", "aws_region")

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Login"
    assert html_response(conn, 200) =~ "/auth/cognito"

    System.put_env("COGNITO_DOMAIN", "")
    System.put_env("COGNITO_CLIENT_ID", "")
    System.put_env("COGNITO_CLIENT_SECRET", "")
    System.put_env("COGNITO_USER_POOL_ID", "")
    System.put_env("COGNITO_AWS_REGION", "")
  end

  test "GET / with partial Cognito auth config does not show a login button", %{conn: conn} do
    System.put_env("COGNITO_DOMAIN", "domain")
    System.put_env("COGNITO_CLIENT_ID", "client_id")
    System.put_env("COGNITO_CLIENT_SECRET", "client_secret")
    System.put_env("COGNITO_USER_POOL_ID", "user_pool_id")
    System.put_env("COGNITO_AWS_REGION", "")

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Go to workspaces"

    System.put_env("COGNITO_DOMAIN", "")
    System.put_env("COGNITO_CLIENT_ID", "")
    System.put_env("COGNITO_CLIENT_SECRET", "")
    System.put_env("COGNITO_USER_POOL_ID", "")
  end

  test "GET / with google auth shows a google auth login button", %{conn: conn} do
    System.put_env("GOOGLE_CLIENT_ID", "client_id")
    System.put_env("GOOGLE_CLIENT_SECRET", "client_secret")

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Login"
    assert html_response(conn, 200) =~ "/auth/google"

    System.put_env("GOOGLE_CLIENT_ID", "")
    System.put_env("GOOGLE_CLIENT_SECRET", "")
  end

  test "GET / with partial Google auth config does not show a login button", %{conn: conn} do
    System.put_env("GOOGLE_CLIENT_ID", "client_id")

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Go to workspaces"

    System.put_env("GOOGLE_CLIENT_ID", "")
  end

  test "GET / without auth does not show a login button", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Go to workspaces"
  end
end
