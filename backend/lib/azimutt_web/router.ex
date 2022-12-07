defmodule AzimuttWeb.Router do
  use AzimuttWeb, :router
  import PhxLiveStorybook.Router
  import AzimuttWeb.UserAuth
  alias AzimuttWeb.Plugs.AllowCrossOriginIframe

  pipeline :browser do
    plug Ueberauth
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AzimuttWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug CORSPlug
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_user
  end

  pipeline :account_session_layout do
    plug :put_root_layout, {AzimuttWeb.LayoutView, :account}
  end

  pipeline :account_dashboard_layout do
    plug :put_root_layout, {AzimuttWeb.LayoutView, :account_dashboard}
  end

  # public routes
  scope "/", AzimuttWeb do
    pipe_through :browser
    get "/", WebsiteController, :index
    get "/last", WebsiteController, :last
    get "/blog", BlogController, :index
    get "/blog/:id", BlogController, :show
    get "/gallery", GalleryController, :index
    get "/gallery/:slug", GalleryController, :show
    get "/logout", UserSessionController, :delete
    delete "/logout", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
    get "/sitemap.xml", SitemapController, :index
  end

  # auth routes
  scope "/", AzimuttWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    get "/auth/:provider", UserOauthController, :request
    get "/auth/:provider/callback", UserOauthController, :callback
    get "/register", UserRegistrationController, :new
    post "/register", UserRegistrationController, :create
    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create
    get "/reset-password", UserResetPasswordController, :new
    post "/reset-password", UserResetPasswordController, :create
    get "/reset-password/:token", UserResetPasswordController, :edit
    put "/reset-password/:token", UserResetPasswordController, :update
  end

  # authed dashboard routes
  scope "/", AzimuttWeb do
    pipe_through [:browser, :require_authenticated_user, :account_dashboard_layout]
    get "/home", UserDashboardController, :index
    get "/login/redirect", UserSessionController, :redirect_to

    resources "/organizations", OrganizationController, except: [:index] do
      get "/billing", OrganizationBillingController, :index, as: :billing
      post "/billing/new", OrganizationBillingController, :new, as: :billing
      post "/billing/edit", OrganizationBillingController, :edit, as: :billing
      get "/billing/success", OrganizationBillingController, :success, as: :billing
      get "/billing/cancel", OrganizationBillingController, :cancel, as: :billing
      get "/members", OrganizationMemberController, :index, as: :member
      post "/members", OrganizationMemberController, :create_invitation, as: :member
      patch "/members/:invitation_id/cancel", OrganizationMemberController, :cancel_invitation, as: :member
      delete "/members/:user_id/remove", OrganizationMemberController, :remove, as: :member
    end

    get "/invitations/:id", OrganizationInvitationController, :show, as: :invitation
    patch "/invitations/:id/accept", OrganizationInvitationController, :accept, as: :invitation
    patch "/invitations/:id/refuse", OrganizationInvitationController, :refuse, as: :invitation
  end

  scope "/heroku", AzimuttWeb do
    pipe_through [:api, :require_heroku_basic_auth]
    post "/resources", Api.HerokuController, :create
    put "/resources/:heroku_id", Api.HerokuController, :update
    delete "/resources/:heroku_id", Api.HerokuController, :delete
  end

  scope "/heroku", AzimuttWeb do
    pipe_through [:browser]
    if Mix.env() == :dev, do: get("/", HerokuController, :index)
    post "/login", HerokuController, :login
  end

  scope "/heroku", AzimuttWeb do
    pipe_through [:browser, :fetch_heroku_resource, :require_heroku_resource]
    get "/resources/:heroku_id", HerokuController, :show
  end

  # authed admin routes
  # scope "/admin", AzimuttWeb do
  #   pipe_through [:browser, :require_authenticated_user]
  # end

  scope "/api/v1/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :azimutt, swagger_file: "swagger.json"
  end

  # public APIs
  scope "/api/v1", AzimuttWeb do
    pipe_through [:api]
    # GET is practical for development and POST allows to not have params in possible http logs
    get "/analyzer/schema", Api.AnalyzerController, :schema
    post "/analyzer/schema", Api.AnalyzerController, :schema
    get "/gallery", Api.GalleryController, :index
    get "/organizations/:organization_id/projects/:id", Api.ProjectController, :show
  end

  # authed APIs
  scope "/api/v1", AzimuttWeb do
    pipe_through [:api, :require_authenticated_user_api]
    get "/users/current", Api.UserController, :current

    resources "/organizations", Api.OrganizationController, only: [:index] do
      resources "/projects", Api.ProjectController, except: [:new, :edit, :show]
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test, :staging] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: AzimuttWeb.Telemetry
    end

    live_storybook("/storybook",
      otp_app: :azimutt,
      backend_module: AzimuttWeb.Storybook
    )
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Azimutt API",
        description: "API Documentation for Azimutt Backend",
        contact: %{
          name: "Azimutt",
          email: "hey@azimutt.app"
        }
      },
      consumes: ["application/json"],
      produces: ["application/json"]
    }
  end

  scope "/", AzimuttWeb do
    pipe_through [:browser, AllowCrossOriginIframe]
    get "/embed", ElmController, :embed
  end

  # elm routes, must be at the end (because of `/:organization_id/:project_id` "catch all")
  # routes listed in the same order than in `elm/src/Pages`
  scope "/", AzimuttWeb do
    pipe_through :browser
    get "/create", ElmController, :create
    get "/new", ElmController, :new
    get "/projects", ElmController, :projects_legacy
    get "/:organization_id", ElmController, :orga_show
    get "/:organization_id/create", ElmController, :orga_create
    get "/:organization_id/new", ElmController, :orga_new
    get "/:organization_id/:project_id", ElmController, :project_show
  end
end
