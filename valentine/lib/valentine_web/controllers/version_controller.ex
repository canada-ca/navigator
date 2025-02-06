defmodule ValentineWeb.VersionController do
  use ValentineWeb, :controller

  def index(conn, _params) do
    version = System.get_env("GIT_SHA") || "unknown"
    json(conn, %{version: version})
  end
end
