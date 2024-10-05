defmodule AzimuttWeb.Router do
  use AzimuttWeb, :router
  import AzimuttWeb.UserAuth
  alias AzimuttWeb.Plugs.AllowCrossOriginIframe

  pipeline :browser_no_csrf_protection do
    plug(Ueberauth)
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {AzimuttWeb.LayoutView, :root_hfull})
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
    plug(:fetch_clever_cloud_resource)
    plug(:fetch_heroku_resource)
    plug(:track_attribution)
  end

  pipeline :browser do
    plug(:browser_no_csrf_protection)
    plug(:protect_from_forgery)
  end

  pipeline :api do
    plug(CORSPlug)
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:fetch_current_user)
    plug(:fetch_clever_cloud_resource)
    plug(:fetch_heroku_resource)
  end

  pipeline(:website_root_layout, do: plug(:put_root_layout, {AzimuttWeb.LayoutView, "root_website.html"}))
  pipeline(:hfull_root_layout, do: plug(:put_root_layout, {AzimuttWeb.LayoutView, "root_hfull.html"}))
  pipeline(:organization_root_layout, do: plug(:put_root_layout, {AzimuttWeb.LayoutView, "root_organization.html"}))
  pipeline(:admin_root_layout, do: plug(:put_root_layout, {AzimuttWeb.LayoutView, "root_admin.html"}))
  pipeline(:elm_root_layout, do: plug(:put_root_layout, {AzimuttWeb.LayoutView, "root_elm.html"}))
  pipeline(:user_settings_root_layout, do: plug(:put_root_layout, {AzimuttWeb.LayoutView, "root_user_settings.html"}))
  pipeline(:empty_layout, do: plug(:put_layout, {AzimuttWeb.LayoutView, "empty.html"}))

  # public routes
  scope "/", AzimuttWeb do
    pipe_through([:browser, :website_root_layout])
    get("/", WebsiteController, :index)
    get("/aml", WebsiteController, :aml)
    get("/portal", WebsiteController, :portal)
    get("/portal/subscribed", WebsiteController, :portal_subscribed)
    # get("/cli", WebsiteController, :cli)
    # get("/analyze", WebsiteController, :analyze)
    # get("/analyze/rules", WebsiteController, :analyze_rules)
    # get("/analyze/rules/:id", WebsiteController, :analyze_rule)
    # get("/connectors", WebsiteController, :connectors)
    # get("/connectors/:id", WebsiteController, :connector)
    get("/converters", WebsiteController, :converters)
    get("/converters/:from", WebsiteController, :converter)
    get("/converters/:from/to/:to", WebsiteController, :convert)
    get("/docs", WebsiteController, :docs)
    get("/docs/:slug", WebsiteController, :doc)
    get("/last", WebsiteController, :last)
    get("/use-cases", WebsiteController, :use_cases_index)
    get("/use-cases/:use_case_id", WebsiteController, :use_cases_show)
    get("/features", WebsiteController, :features_index)
    get("/features/:feature_id", WebsiteController, :features_show)
    get("/pricing", WebsiteController, :pricing)
    get("/blog", BlogController, :index)
    if Azimutt.Application.env() == :dev, do: get("/blog/cards", BlogController, :cards)
    get("/blog/:article_id", BlogController, :show)
    get("/gallery", GalleryController, :index)
    get("/gallery/:slug", GalleryController, :show)
    # get("/vs", WebsiteController, :vs_tools)
    # get("/vs/:tool", WebsiteController, :vs_tool)
    # get("/database-tools", WebsiteController, :db_tools)
    # get("/database-tools/:tool", WebsiteController, :db_tool)
    # get("/friends", WebsiteController, :friends)
    # get("/friends/:friend", WebsiteController, :friend)
    get("/logout", UserSessionController, :delete)
    delete("/logout", UserSessionController, :delete)
    get("/sitemap.xml", SitemapController, :index)
    get("/terms", WebsiteController, :terms)
    get("/privacy", WebsiteController, :privacy)
    get("/resources", WebsiteController, :resources)
  end

  # auth routes
  scope "/", AzimuttWeb do
    pipe_through([:browser, :redirect_if_user_is_authed, :hfull_root_layout])
    get("/auth/:provider", UserOauthController, :request)
    get("/auth/:provider/callback", UserOauthController, :callback)
    get("/register", UserRegistrationController, :new)
    post("/register", UserRegistrationController, :create)
    get("/login", UserSessionController, :new)
    post("/login", UserSessionController, :create)
    get("/reset-password", UserResetPasswordController, :new)
    post("/reset-password", UserResetPasswordController, :create)
    get("/reset-password/:token", UserResetPasswordController, :edit)
    put("/reset-password/:token", UserResetPasswordController, :update)
  end

  # authed dashboard routes
  scope "/", AzimuttWeb do
    pipe_through([:browser, :require_authed_user, :organization_root_layout, AllowCrossOriginIframe])
    get("/home", UserDashboardController, :index)
    get("/billing", UserDashboardController, :billing)
    get("/login/redirect", UserSessionController, :redirect_to)
    get("/subscribe/:plan/:freq", SubscribeController, :index)

    scope "/email-confirm" do
      pipe_through([:hfull_root_layout])
      get("/", UserConfirmationController, :new)
      post("/", UserConfirmationController, :create)
      get("/:token", UserConfirmationController, :confirm)
    end

    scope "/onboarding" do
      pipe_through([:hfull_root_layout, :empty_layout])
      get("/", UserOnboardingController, :index)
      get("/welcome", UserOnboardingController, :welcome)
      post("/welcome", UserOnboardingController, :welcome_next)
      get("/explore-or-design", UserOnboardingController, :explore_or_design)
      post("/explore-or-design", UserOnboardingController, :explore_or_design_next)
      get("/solo-or-team", UserOnboardingController, :solo_or_team)
      post("/solo-or-team", UserOnboardingController, :solo_or_team_next)
      get("/role", UserOnboardingController, :role)
      post("/role", UserOnboardingController, :role_next)
      get("/about-you", UserOnboardingController, :about_you)
      put("/about-you", UserOnboardingController, :about_you_next)
      get("/about-your-company", UserOnboardingController, :about_your_company)
      put("/about-your-company", UserOnboardingController, :about_your_company_next)
      get("/plan", UserOnboardingController, :plan)
      post("/plan", UserOnboardingController, :plan_next)
      get("/discovered-azimutt", UserOnboardingController, :discovered_azimutt)
      put("/discovered-azimutt", UserOnboardingController, :discovered_azimutt_next)
      get("/previous-solutions", UserOnboardingController, :previous_solutions)
      put("/previous-solutions", UserOnboardingController, :previous_solutions_next)
      get("/keep-in-touch", UserOnboardingController, :keep_in_touch)
      put("/keep-in-touch", UserOnboardingController, :keep_in_touch_next)
      get("/community", UserOnboardingController, :community)
      post("/community", UserOnboardingController, :community_next)
      get("/finalize", UserOnboardingController, :finalize)

      if Azimutt.Application.env() == :dev, do: get("/:template", UserOnboardingController, :template)
    end

    scope "/settings" do
      pipe_through([:user_settings_root_layout, :empty_layout])
      get("/", UserSettingsController, :show)
      put("/account", UserSettingsController, :update_account)
      put("/email", UserSettingsController, :update_email)
      get("/email/:token", UserSettingsController, :confirm_update_email)
      put("/password", UserSettingsController, :update_password)
      post("/password", UserSettingsController, :set_password)
      delete("/providers/:provider", UserSettingsController, :remove_provider)
      post("/auth-tokens", UserSettingsController, :create_auth_token)
      delete("/auth-tokens/:token_id", UserSettingsController, :delete_auth_token)
    end

    resources "/organizations", OrganizationController, param: "organization_id", except: [:index] do
      get("/billing", OrganizationBillingController, :index, as: :billing)
      post("/billing/refresh", OrganizationBillingController, :refresh, as: :billing)
      get("/billing/new", OrganizationBillingController, :new, as: :billing)
      post("/billing/edit", OrganizationBillingController, :edit, as: :billing)
      get("/billing/success", OrganizationBillingController, :success, as: :billing)
      get("/billing/cancel", OrganizationBillingController, :cancel, as: :billing)
      get("/members", OrganizationMemberController, :index, as: :member)
      post("/members", OrganizationMemberController, :create_invitation, as: :member)
      patch("/members/:invitation_id/cancel", OrganizationMemberController, :cancel_invitation, as: :member)
      put("/members/:user_id/role/:role", OrganizationMemberController, :set_role, as: :member)
      delete("/members/:user_id/remove", OrganizationMemberController, :remove, as: :member)
      post("/check/:item", StartChecklistController, :check, as: :start_checklist)
    end

    get("/invitations/:invitation_id", OrganizationInvitationController, :show, as: :invitation)
    patch("/invitations/:invitation_id/accept", OrganizationInvitationController, :accept, as: :invitation)
    patch("/invitations/:invitation_id/refuse", OrganizationInvitationController, :refuse, as: :invitation)
  end

  scope "/heroku", AzimuttWeb do
    pipe_through([:api, :require_heroku_basic_auth])
    post("/resources", Api.HerokuController, :create)
    put("/resources/:resource_id", Api.HerokuController, :update)
    delete("/resources/:resource_id", Api.HerokuController, :delete)
  end

  scope "/heroku", AzimuttWeb do
    pipe_through([:browser_no_csrf_protection])
    if Azimutt.Application.env() == :dev, do: get("/", HerokuController, :index)
    post("/login", HerokuController, :login)
  end

  scope "/heroku", AzimuttWeb do
    pipe_through([:browser, :require_heroku_resource, :require_authed_user])
    get("/resources/:resource_id", HerokuController, :show)
  end

  scope "/clevercloud", AzimuttWeb do
    pipe_through([:api, :require_clever_cloud_basic_auth])
    post("/resources", Api.CleverCloudController, :create)
    post("/resources/:resource_id", Api.CleverCloudController, :update)
    post("/resources/:resource_id/migrations", Api.CleverCloudController, :migrations)
    delete("/resources/:resource_id", Api.CleverCloudController, :delete)
  end

  scope "/clevercloud", AzimuttWeb do
    pipe_through([:browser_no_csrf_protection, AllowCrossOriginIframe])
    if Azimutt.Application.env() == :dev, do: get("/", CleverCloudController, :index)
    post("/login", CleverCloudController, :login)
  end

  scope "/clevercloud", AzimuttWeb do
    pipe_through([:browser, :require_clever_cloud_resource, :require_authed_user, AllowCrossOriginIframe])
    get("/resources/:resource_id", CleverCloudController, :show)
  end

  scope "/admin", AzimuttWeb, as: :admin do
    pipe_through([:browser, :require_authed_user, :require_admin_user, :admin_root_layout])
    get("/", Admin.DashboardController, :index)
    resources("/users", Admin.UserController, param: "user_id", only: [:index, :show])
    resources("/organizations", Admin.OrganizationController, param: "organization_id", only: [:index, :show])
    post("/organizations/:organization_id/refresh", Admin.OrganizationController, :refresh)
    resources("/projects", Admin.ProjectController, param: "project_id", only: [:index, :show])
    resources("/events", Admin.EventController, param: "event_id", only: [:index, :show])
  end

  scope "/api/v1/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :azimutt, swagger_file: "swagger.json")
  end

  # public APIs
  scope "/", AzimuttWeb do
    pipe_through([:api])
    get("/aml/schema", Api.MainController, :aml_schema)

    scope "/api" do
      get("/", Api.MainController, :index)

      scope "/v1" do
        get("/", Api.MainController, :index)
        get("/gallery", Api.GalleryController, :index)
        get("/organizations/:organization_id/projects/:project_id", Api.ProjectController, :show)
        resources("/organizations/:organization_id/projects/:project_id/sources", Api.SourceController, param: "source_id", only: [:index, :show, :create, :update, :delete])
        get("/organizations/:organization_id/projects/:project_id/metadata", Api.MetadataController, :index)
        put("/organizations/:organization_id/projects/:project_id/metadata", Api.MetadataController, :update)
        get("/organizations/:organization_id/projects/:project_id/tables/:table_id/metadata", Api.MetadataController, :table)
        put("/organizations/:organization_id/projects/:project_id/tables/:table_id/metadata", Api.MetadataController, :table_update)
        get("/organizations/:organization_id/projects/:project_id/tables/:table_id/columns/:column_path/metadata", Api.MetadataController, :column)
        put("/organizations/:organization_id/projects/:project_id/tables/:table_id/columns/:column_path/metadata", Api.MetadataController, :column_update)
        post("/events", Api.TrackingController, :create)
      end
    end
  end

  # authed APIs
  scope "/api/v1", AzimuttWeb do
    pipe_through([:api, :require_authed_user_api])
    get("/users/current", Api.UserController, :current)

    resources "/organizations", Api.OrganizationController, param: "organization_id", only: [:index] do
      resources "/projects", Api.ProjectController, param: "project_id", except: [:new, :edit, :show] do
        resources("/access-tokens", Api.ProjectTokenController, param: "token_id", only: [:index, :create, :delete])
      end

      post("/tweet-for-table-colors", Api.OrganizationController, :table_colors)
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Azimutt.Application.env() in [:dev, :test, :staging] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: AzimuttWeb.Telemetry)
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Azimutt.Application.env() == :dev do
    scope "/dev" do
      pipe_through(:browser)

      forward("/mailbox", Plug.Swoosh.MailboxPreview)
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
          email: Azimutt.config(:contact_email)
        }
      },
      basePath: "/api/v1",
      consumes: ["application/json"],
      produces: ["application/json"]
    }
  end

  scope "/", AzimuttWeb do
    pipe_through([:browser, :elm_root_layout, AllowCrossOriginIframe])
    get("/embed", ElmController, :embed)
  end

  scope "/", AzimuttWeb do
    pipe_through([:api])
    get("/ping", Api.HealthController, :ping)
    get("/health", Api.HealthController, :health)
  end

  # elm routes, must be at the end (because of `/:organization_id/:project_id` "catch all")
  # routes listed in the same order than in `elm/src/Pages`
  scope "/", AzimuttWeb do
    pipe_through([:browser, :enforce_user_requirements, :elm_root_layout])
    get("/create", ElmController, :create)
    get("/new", ElmController, :new)
    get("/:organization_id", ElmController, :org_show)
  end

  # allow cross origin iframe for Clever Cloud
  scope "/", AzimuttWeb do
    pipe_through([:browser, :enforce_user_requirements, :elm_root_layout, AllowCrossOriginIframe])
    get("/:organization_id/new", ElmController, :org_new)
    post("/:organization_id/new", ElmController, :org_new)
    get("/:organization_id/create", ElmController, :org_create)
    post("/:organization_id/create", ElmController, :org_create)
    get("/:organization_id/:project_id", ElmController, :project_show)
  end
end
