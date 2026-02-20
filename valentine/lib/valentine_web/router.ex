defmodule ValentineWeb.Router do
  use ValentineWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ValentineWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self' style-src 'self' 'unsafe-inline' img-src 'self' data:"
    }
  end

  pipeline :authenticated do
    plug ValentineWeb.Helpers.AuthHelper
    plug ValentineWeb.Helpers.RbacHelper
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug ValentineWeb.Helpers.ApiAuthHelper
  end

  pipeline :raw do
    plug :accepts, ["html", "json"]
  end

  scope "/", ValentineWeb do
    pipe_through :raw

    get "/version", VersionController, :index
  end

  scope "/api", ValentineWeb.Api do
    pipe_through :api

    get "/workspace", WorkspaceController, :index
    post "/evidence", EvidenceController, :create
  end

  scope "/auth", ValentineWeb do
    pipe_through :browser

    get "/google", AuthController, :request
    get "/google/callback", AuthController, :callback

    get "/cognito", AuthController, :request
    get "/cognito/callback", AuthController, :callback

    get "/microsoft", AuthController, :request
    get "/microsoft/callback", AuthController, :callback
  end

  scope "/", ValentineWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", ValentineWeb do
    pipe_through :browser
    pipe_through :authenticated

    get "/workspaces/:workspace_id/export", WorkspaceController, :export
    get "/workspaces/:workspace_id/export/assumptions", WorkspaceController, :export_assumptions
    get "/workspaces/:workspace_id/export/mitigations", WorkspaceController, :export_mitigations
    get "/workspaces/:workspace_id/export/threats", WorkspaceController, :export_threats
    get "/workspaces/:workspace_id/data_flow/mermaid", WorkspaceController, :export_dfd_mermaid
    get "/workspaces/:workspace_id/threat_model/markdown", WorkspaceController, :markdown
    get "/workspaces/:workspace_id/srtm/excel", WorkspaceController, :excel

    get "/logout", SessionController, :logout
    post "/session", SessionController, :create

    live_session :authenticated,
      on_mount: [
        ValentineWeb.Helpers.AuthHelper,
        ValentineWeb.Helpers.RbacHelper,
        ValentineWeb.Helpers.ChatHelper,
        ValentineWeb.Helpers.ControlHelper,
        ValentineWeb.Helpers.FlashHelper,
        ValentineWeb.Helpers.LocaleHelper,
        ValentineWeb.Helpers.NavHelper,
        ValentineWeb.Helpers.PresenceHelper,
        ValentineWeb.Helpers.ThemeHelper
      ] do
      live "/workspaces", WorkspaceLive.Index, :index
      live "/workspaces/import", WorkspaceLive.Index, :import
      live "/workspaces/new", WorkspaceLive.Index, :new
      live "/workspaces/:workspace_id/edit", WorkspaceLive.Index, :edit

      live "/workspaces/:workspace_id", WorkspaceLive.Show, :show

      live "/workspaces/:workspace_id/assumptions", WorkspaceLive.Assumption.Index, :index
      live "/workspaces/:workspace_id/assumptions/new", WorkspaceLive.Assumption.Index, :new
      live "/workspaces/:workspace_id/assumptions/:id/edit", WorkspaceLive.Assumption.Index, :edit

      live "/workspaces/:workspace_id/assumptions/:id/mitigations",
           WorkspaceLive.Assumption.Index,
           :mitigations

      live "/workspaces/:workspace_id/assumptions/:id/threats",
           WorkspaceLive.Assumption.Index,
           :threats

      live "/workspaces/:workspace_id/application_information",
           WorkspaceLive.ApplicationInformation.Index,
           :index

      live "/workspaces/:workspace_id/architecture",
           WorkspaceLive.Architecture.Index,
           :index

      live "/workspaces/:workspace_id/data_flow", WorkspaceLive.DataFlow.Index, :index

      live "/workspaces/:workspace_id/brainstorm", WorkspaceLive.Brainstorm.Index, :index

      live "/workspaces/:workspace_id/mitigations", WorkspaceLive.Mitigation.Index, :index
      live "/workspaces/:workspace_id/mitigations/new", WorkspaceLive.Mitigation.Index, :new
      live "/workspaces/:workspace_id/mitigations/:id/edit", WorkspaceLive.Mitigation.Index, :edit

      live "/workspaces/:workspace_id/mitigations/:id/assumptions",
           WorkspaceLive.Mitigation.Index,
           :assumptions

      live "/workspaces/:workspace_id/mitigations/:id/categorize",
           WorkspaceLive.Mitigation.Index,
           :categorize

      live "/workspaces/:workspace_id/mitigations/:id/threats",
           WorkspaceLive.Mitigation.Index,
           :threats

      live "/workspaces/:workspace_id/evidence", WorkspaceLive.Evidence.Index, :index
      live "/workspaces/:workspace_id/evidence/new", WorkspaceLive.Evidence.Show, :new
      live "/workspaces/:workspace_id/evidence/:id", WorkspaceLive.Evidence.Show, :edit

      live "/workspaces/:workspace_id/threats", WorkspaceLive.Threat.Index, :index
      live "/workspaces/:workspace_id/threats/new", WorkspaceLive.Threat.Show, :new
      live "/workspaces/:workspace_id/threats/:id", WorkspaceLive.Threat.Show, :edit

      live "/workspaces/:workspace_id/threats/:id/assumption",
           WorkspaceLive.Threat.Show,
           :new_assumption

      live "/workspaces/:workspace_id/threats/:id/assumptions",
           WorkspaceLive.Threat.Index,
           :assumptions

      live "/workspaces/:workspace_id/threats/:id/mitigation",
           WorkspaceLive.Threat.Show,
           :new_mitigation

      live "/workspaces/:workspace_id/threats/:id/mitigations",
           WorkspaceLive.Threat.Index,
           :mitigations

      live "/workspaces/:workspace_id/threat_model", WorkspaceLive.ThreatModel.Index, :index

      live "/workspaces/:workspace_id/reference_packs", WorkspaceLive.ReferencePacks.Index, :index

      live "/workspaces/:workspace_id/reference_packs/import",
           WorkspaceLive.ReferencePacks.Index,
           :import

      live "/workspaces/:workspace_id/reference_packs/:collection_id/:collection_type",
           WorkspaceLive.ReferencePacks.Show,
           :show

      live "/workspaces/:workspace_id/srtm", WorkspaceLive.SRTM.Index, :index

      live "/workspaces/:workspace_id/controls", WorkspaceLive.Controls.Index, :index

      live "/workspaces/:workspace_id/collaboration", WorkspaceLive.Collaboration.Index, :index

      live "/workspaces/:workspace_id/api_keys", WorkspaceLive.ApiKey.Index, :index

      live "/workspaces/:workspace_id/api_keys/generate",
           WorkspaceLive.ApiKey.Index,
           :generate
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ValentineWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:valentine, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ValentineWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
