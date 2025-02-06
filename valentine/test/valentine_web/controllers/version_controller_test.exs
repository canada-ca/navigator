defmodule ValentineWeb.VersionControllerTest do
  use ValentineWeb.ConnCase

  test "GET /version", %{conn: conn} do
    conn = get(conn, "/version")
    assert json_response(conn, 200)["version"] == "unknown"
  end

  test "GET /version with GIT_SHA set", %{conn: conn} do
    System.put_env("GIT_SHA", "1234")
    conn = get(conn, "/version")
    assert json_response(conn, 200)["version"] == "1234"
    System.delete_env("GIT_SHA")
  end
end
