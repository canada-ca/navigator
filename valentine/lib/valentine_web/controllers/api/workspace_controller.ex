defmodule ValentineWeb.Api.WorkspaceController do
  use ValentineWeb, :controller

  alias Valentine.Composer

  def index(conn, _params) do
    key = conn.assigns[:api_key]

    # Load the workspace data
    workspace = Composer.get_workspace!(key.workspace_id)
    json(conn, %{workspace: workspace})
  end
end
