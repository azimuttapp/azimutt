import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/azimutt start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
host = System.fetch_env!("PHX_HOST")
port = String.to_integer(System.fetch_env!("PORT"))
global_organization = System.get_env("GLOBAL_ORGANIZATION")
# TODO: REQUIRE_GITHUB_ORGANIZATION: allow users only from this github orga

config :azimutt,
  host: host,
  gateway_url: System.get_env("GATEWAY_URL") || "/api/v1/analyzer",
  skip_public_site: !(System.get_env("PUBLIC_SITE") == "true"),
  skip_onboarding_funnel: System.get_env("SKIP_ONBOARDING_FUNNEL") == "true",
  skip_email_confirmation: System.get_env("SKIP_EMAIL_CONFIRMATION") == "true",
  require_email_confirmation: System.get_env("REQUIRE_EMAIL_CONFIRMATION") == "true",
  require_email_ends_with: System.get_env("REQUIRE_EMAIL_ENDS_WITH"),
  organization_default_plan: System.get_env("ORGANIZATION_DEFAULT_PLAN"),
  global_organization: global_organization,
  global_organization_alone: global_organization && System.get_env("GLOBAL_ORGANIZATION_ALONE") == "true",
  support_email: System.get_env("SUPPORT_EMAIL") || "contact@azimutt.app",
  sender_email: System.get_env("SENDER_EMAIL") || "contact@azimutt.app",
  server_started: DateTime.utc_now()

config :azimutt, Azimutt.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("DATABASE_POOL_SIZE") || "10"),
  socket_options: if(System.get_env("DATABASE_IPV6") == "true", do: [:inet6], else: []),
  show_sensitive_data_on_connection_error: config_env() == :dev,
  stacktrace: config_env() == :dev

if System.get_env("DATABASE_ENABLE_SSL") == "true" do
  config :azimutt, Azimutt.Repo,
    ssl: true,
    ssl_opts: [
      verify: :verify_none
    ]
end

if config_env() == :test, do: config(:azimutt, Azimutt.Repo, pool: Ecto.Adapters.SQL.Sandbox)

if config_env() == :prod || config_env() == :staging do
  if System.get_env("PHX_SERVER") == "true", do: config(:azimutt, AzimuttWeb.Endpoint, server: true)

  config :azimutt, AzimuttWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
end

config :azimutt, file_storage: System.fetch_env!("FILE_STORAGE_ADAPTER")

case System.fetch_env!("FILE_STORAGE_ADAPTER") do
  "local" ->
    IO.puts("Setup Local file storage")
    config :waffle, storage: Waffle.Storage.Local
    config :ex_aws, json_codec: Jason

  "s3" ->
    IO.puts("Setup S3 file storage")
    s3_host = System.get_env("S3_HOST") || ""
    s3_key_id = System.get_env("S3_KEY_ID") || ""
    s3_key_secret = System.get_env("S3_KEY_SECRET") || ""
    s3_region = System.get_env("S3_REGION") || "eu-west-1"
    s3_bucket = System.fetch_env!("S3_BUCKET")
    config :azimutt, s3_folder: System.get_env("S3_FOLDER")

    # https://hexdocs.pm/waffle/Waffle.Storage.S3.html
    if s3_host != "" do
      config :waffle,
        storage: Waffle.Storage.S3,
        bucket: s3_bucket,
        asset_host: s3_host

      config :ex_aws, :s3,
        scheme: "https://",
        host: s3_host,
        region: s3_region
    else
      config :waffle,
        storage: Waffle.Storage.S3,
        bucket: s3_bucket

      config :ex_aws,
        region: s3_region,
        s3: [
          scheme: "https://",
          region: s3_region
        ]
    end

    if s3_key_id != "" && s3_key_secret != "" do
      config :ex_aws,
        debug_requests: true,
        json_codec: Jason,
        access_key_id: s3_key_id,
        secret_access_key: s3_key_secret
    end

  adapter ->
    raise "unknown FILE_STORAGE_ADAPTER '#{adapter}', expected values: local or s3"
end

config :azimutt, email_service: System.get_env("EMAIL_ADAPTER")

case System.get_env("EMAIL_ADAPTER") do
  "mailgun" ->
    IO.puts("Setup Mailgun email provider")
    # https://hexdocs.pm/swoosh/Swoosh.Adapters.Mailgun.html
    config :azimutt, Azimutt.Mailer,
      adapter: Swoosh.Adapters.Mailgun,
      api_key: System.fetch_env!("MAILGUN_API_KEY"),
      domain: System.fetch_env!("MAILGUN_DOMAIN"),
      base_url: System.fetch_env!("MAILGUN_BASE_URL")

  "gmail" ->
    IO.puts("Setup Gmail email provider")
    # https://hexdocs.pm/swoosh/Swoosh.Adapters.Gmail.html
    config :azimutt, Azimutt.Mailer,
      adapter: Swoosh.Adapters.Gmail,
      access_token: System.fetch_env!("GMAIL_ACCESS_TOKEN")

  "smtp" ->
    IO.puts("Setup SMTP email provider")
    # https://hexdocs.pm/swoosh/Swoosh.Adapters.SMTP.html
    config :azimutt, Azimutt.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: System.fetch_env!("SMTP_RELAY"),
      username: System.fetch_env!("SMTP_USERNAME"),
      password: System.fetch_env!("SMTP_PASSWORD"),
      port: String.to_integer(System.fetch_env!("SMTP_PORT")),
      # ssl: true,
      # tls: :always,
      # auth: :always,
      retries: 2,
      no_mx_lookups: false

  _ ->
    if config_env() == :test do
      IO.puts("Setup Test email provider")
      config :azimutt, Azimutt.Mailer, adapter: Swoosh.Adapters.Test
    else
      IO.puts("Setup Local email provider")
      config :azimutt, Azimutt.Mailer, adapter: Swoosh.Adapters.Local
    end
end

config :swoosh, :api_client, Swoosh.ApiClient.Hackney

if System.get_env("AUTH_PASSWORD") == "true" do
  IO.puts("Setup Password auth")
  config :azimutt, auth_password: true
end

if System.get_env("AUTH_GITHUB") == "true" do
  IO.puts("Setup Github auth")
  config :azimutt, auth_github: true

  config :ueberauth, Ueberauth.Strategy.Github.OAuth,
    client_id: System.fetch_env!("GITHUB_CLIENT_ID"),
    client_secret: System.fetch_env!("GITHUB_CLIENT_SECRET")
end

if System.get_env("AUTH_GOOGLE") == "true" do
  IO.puts("Setup Google auth")
  config :azimutt, auth_google: true
  raise "AUTH_GOOGLE not implemented"
end

if System.get_env("AUTH_LINKEDIN") == "true" do
  IO.puts("Setup LinkedIn auth")
  config :azimutt, auth_linkedin: true
  raise "AUTH_LINKEDIN not implemented"
end

if System.get_env("AUTH_TWITTER") == "true" do
  IO.puts("Setup Twitter auth")
  config :azimutt, auth_twitter: true
  raise "AUTH_TWITTER not implemented"
end

if System.get_env("AUTH_FACEBOOK") == "true" do
  IO.puts("Setup Facebook auth")
  config :azimutt, auth_facebook: true
  raise "AUTH_FACEBOOK not implemented"
end

if System.get_env("AUTH_SAML") == "true" do
  IO.puts("Setup SAML auth")
  # https://github.com/wrren/ueberauth_saml
  config :azimutt, auth_saml: true
  raise "AUTH_SAML not implemented"
end

# if System.get_env("AUTH_PASSWORD") != "true" && System.get_env("AUTH_GITHUB") != "true" do
#   raise "No auth method defined, please set one, for example: AUTH_PASSWORD=true"
# end

if System.get_env("POSTHOG") == "true" do
  IO.puts("Setup PostHog")

  config :azimutt,
    posthog: true,
    posthog_host: System.fetch_env!("POSTHOG_HOST"),
    posthog_key: System.fetch_env!("POSTHOG_KEY")

  config :posthog,
    api_url: System.fetch_env!("POSTHOG_HOST"),
    api_key: System.fetch_env!("POSTHOG_KEY")
end

if System.get_env("SENTRY") == "true" do
  IO.puts("Setup Sentry")
  sentry_backend_dsn = System.get_env("SENTRY_BACKEND_DSN")
  sentry_frontend_dsn = System.get_env("SENTRY_FRONTEND_DSN")
  config :azimutt, sentry: true

  if sentry_backend_dsn do
    config :sentry,
      dsn: sentry_backend_dsn,
      environment_name: config_env(),
      release: Azimutt.config(:version),
      enable_source_code_context: true,
      root_source_code_path: File.cwd!(),
      tags: %{env: config_env() |> Atom.to_string()},
      included_environments: [config_env()]
  end

  if sentry_frontend_dsn do
    config :azimutt,
      sentry_frontend_dsn: sentry_frontend_dsn
  end
end

# https://dashboard.stripe.com/test/apikeys & https://dashboard.stripe.com/account/webhooks
if System.get_env("STRIPE") == "true" do
  IO.puts("Setup Stripe")

  config :azimutt,
    stripe: true,
    stripe_price_pro_monthly: System.fetch_env!("STRIPE_PRICE_PRO_MONTHLY")

  config :stripity_stripe,
    api_key: System.fetch_env!("STRIPE_API_KEY"),
    signing_secret: System.fetch_env!("STRIPE_WEBHOOK_SIGNING_SECRET")
end

if System.get_env("CLEVER_CLOUD") == "true" do
  IO.puts("Setup Clever Cloud addon")

  config :azimutt,
    auth_clever_cloud: true,
    clever_cloud_addon_id: System.fetch_env!("CLEVER_CLOUD_ADDON_ID"),
    clever_cloud_password: System.fetch_env!("CLEVER_CLOUD_PASSWORD"),
    clever_cloud_sso_salt: System.fetch_env!("CLEVER_CLOUD_SSO_SALT")
end

if System.get_env("HEROKU") == "true" do
  IO.puts("Setup Heroku addon")

  config :azimutt,
    auth_heroku: true,
    heroku_addon_id: System.fetch_env!("HEROKU_ADDON_ID"),
    heroku_password: System.fetch_env!("HEROKU_PASSWORD"),
    heroku_sso_salt: System.fetch_env!("HEROKU_SSO_SALT")
end

if System.get_env("BENTO") == "true" do
  IO.puts("Setup Bento integration")

  config :azimutt,
    bento: true,
    bento_site_key: System.fetch_env!("BENTO_SITE_KEY"),
    bento_publishable_key: System.fetch_env!("BENTO_PUBLISHABLE_KEY"),
    bento_secret_key: System.fetch_env!("BENTO_SECRET_KEY")
end

if System.get_env("TWITTER") == "true" do
  IO.puts("Setup Twitter integration")
  config :azimutt, twitter: true

  config :extwitter, :oauth,
    consumer_key: System.fetch_env!("TWITTER_CONSUMER_KEY"),
    consumer_secret: System.fetch_env!("TWITTER_CONSUMER_SECRET"),
    access_token: System.fetch_env!("TWITTER_ACCESS_TOKEN"),
    access_token_secret: System.fetch_env!("TWITTER_ACCESS_SECRET")
end

if System.get_env("GITHUB") == "true" do
  IO.puts("Setup Github integration")
  config :azimutt, github: true

  config :azimutt,
    github_access_token: System.fetch_env!("GITHUB_ACCESS_TOKEN")
end
