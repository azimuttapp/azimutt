defmodule AzimuttWeb.Router do
  use AzimuttWeb, :router
  import PhxLiveStorybook.Router
  import AzimuttWeb.UserAuth

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
    get "/", PageController, :index
    get "/blog", BlogController, :index
    get "/blog/:id", BlogController, :show
    get "/logout", UserSessionController, :delete
    delete "/logout", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
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
      # FIXME: don't work, still useful? get "/projects", ProjectController, :index
      get "/billing", OrganizationBillingController, :index, as: :billing
      get "/members", OrganizationMemberController, :index, as: :member
      post "/members/invite", OrganizationMemberController, :invite, as: :member
    end

    get "/invitations/:id", OrganizationInvitationController, :show, as: :invitation
    patch "/invitations/:id/accept", OrganizationInvitationController, :accept, as: :invitation
    patch "/invitations/:id/refuse", OrganizationInvitationController, :refuse, as: :invitation
    patch "/invitations/:id/cancel", OrganizationInvitationController, :cancel, as: :invitation
  end

  # authed session routes
  scope "/", AzimuttWeb do
    pipe_through [:browser, :require_authenticated_user, :account_session_layout]
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    get "/plans", UserPlanController, :index
    post "/plans/new", UserPlanController, :new
    get "/plans/new/success", UserPlanController, :success
    get "/plans/new/cancel", UserPlanController, :cancel
    post "/plans/manage", UserPlanController, :edit
  end

  # authed admin routes
  # FIXME: doesn't work :(
  # scope "/admin", AzimuttWeb do
  #   pipe_through [:browser, :require_authenticated_user]
  #   get "/users/projects", ProjectController, :index
  #   resources "/organizations", OrganizationController
  # end

  # FIXME '/api' will catch all :(
  scope "/api/v1/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :azimutt, swagger_file: "swagger.json"
  end

  # public APIs
  scope "/api/v1", AzimuttWeb do
    pipe_through [:api]
    # GET is practical for development and POST allows to not have params in possible http logs
    get "/analyzer/schema", Api.AnalyzerController, :schema
    post "/analyzer/schema", Api.AnalyzerController, :schema
  end

  # authed APIs
  scope "/api/v1", AzimuttWeb do
    pipe_through [:api, :require_authenticated_user_api]
    get "/users/current", Api.UserController, :current

    resources "/organizations", Api.OrganizationController, only: [:index] do
      resources "/projects", Api.ProjectController, except: [:new, :edit]
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

  # elm routes, must be at the end (because of `/:organization_id/:project_id` "catch all")
  # routes listed in the same order than in `elm/src/Pages`
  scope "/", AzimuttWeb do
    pipe_through :browser
    get "/create", ElmController, :create
    get "/embed", ElmController, :embed
    get "/last", ElmController, :last
    get "/new", ElmController, :new
    get "/projects", ElmController, :projects_legacy
    get "/:organization_id", ElmController, :orga_show
    get "/:organization_id/create", ElmController, :orga_create
    get "/:organization_id/new", ElmController, :orga_new
    get "/:organization_id/:project_id", ElmController, :project_show
  end
end
