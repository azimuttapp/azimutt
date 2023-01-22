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

if System.get_env("PHX_SERVER") do
  config :azimutt, AzimuttWeb.Endpoint, server: true
end

github_client_id = System.get_env("GITHUB_CLIENT_ID")
github_client_secret = System.get_env("GITHUB_CLIENT_SECRET")

if github_client_id && github_client_secret do
  IO.puts("Setup Github auth")

  config :ueberauth, Ueberauth.Strategy.Github.OAuth,
    client_id: github_client_id,
    client_secret: github_client_secret
else
  # FIXME: make email/password signup available
  IO.puts("Github auth not setup (GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET env variables not found)")
end

# https://dashboard.stripe.com/test/apikeys
stripe_api_key = System.get_env("STRIPE_API_KEY")
# https://dashboard.stripe.com/account/webhooks
stripe_webhook_key = System.get_env("STRIPE_WEBHOOK_SIGNING_SECRET")

if stripe_api_key && stripe_webhook_key do
  IO.puts("Setup Stripe")

  config :stripity_stripe,
    api_key: stripe_api_key,
    signing_secret: stripe_webhook_key
else
  IO.puts("Stripe not setup (STRIPE_API_KEY and STRIPE_WEBHOOK_SIGNING_SECRET env variables not found)")
end

heroku_addon_id = System.get_env("HEROKU_ADDON_ID")
heroku_password = System.get_env("HEROKU_PASSWORD")
heroku_sso_salt = System.get_env("HEROKU_SSO_SALT")

if heroku_addon_id && heroku_password && heroku_sso_salt do
  IO.puts("Setup Heroku addon")

  config :azimutt,
    heroku_addon_id: heroku_addon_id,
    heroku_password: heroku_password,
    heroku_sso_salt: heroku_sso_salt
else
  IO.puts("Heroku addon not setup (HEROKU_ADDON_ID, HEROKU_PASSWORD and HEROKU_SSO_SALT env variables not found)")
end

if config_env() != :test do
  config :azimutt,
    domain: System.get_env("PHX_HOST") || raise("environment variable PHX_HOST is missing.")

  cellar_bucket = System.get_env("CELLAR_BUCKET") || raise "environment variable CELLAR_BUCKET is missing."
  cellar_host = System.get_env("CELLAR_ADDON_HOST") || raise "environment variable CELLAR_ADDON_HOST is missing."
  cellar_addon_key_id = System.get_env("CELLAR_ADDON_KEY_ID") || raise "environment variable CELLAR_ADDON_KEY_ID is missing."
  cellar_addon_key_secret = System.get_env("CELLAR_ADDON_KEY_SECRET") || raise "environment variable CELLAR_ADDON_KEY_SECRET is missing."

  config :waffle,
    storage: Waffle.Storage.S3,
    bucket: cellar_bucket,
    asset_host: cellar_host

  config :ex_aws,
    debug_requests: true,
    json_codec: Jason,
    access_key_id: cellar_addon_key_id,
    secret_access_key: cellar_addon_key_secret

  config :ex_aws, :s3,
    scheme: "https://",
    host: cellar_host,
    region: "eu-west-1"
end

if config_env() == :prod || config_env() == :staging do
  database_url =
    System.get_env("POSTGRESQL_ADDON_URI") ||
      raise """
      environment variable POSTGRESQL_ADDON_URI is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :azimutt, Azimutt.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || raise "environment variable PHX_HOST is missing."
  port = String.to_integer(System.get_env("PORT") || raise("environment variable PORT is missing."))

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
    secret_key_base: secret_key_base

  mailgun_api_key = System.get_env("MAILGUN_API_KEY")
  mailgun_domain = System.get_env("MAILGUN_DOMAIN")
  mailgun_base_url = System.get_env("MAILGUN_BASE_URL")

  if mailgun_api_key && mailgun_domain && mailgun_base_url do
    config :azimutt, Azimutt.Mailer,
      adapter: Swoosh.Adapters.Mailgun,
      api_key: mailgun_api_key,
      domain: mailgun_domain,
      base_url: mailgun_base_url
  else
    raise "missing mailgun environment variables: MAILGUN_API_KEY, MAILGUN_DOMAIN and MAILGUN_BASE_URL"
  end

  config :swoosh, :api_client, Swoosh.ApiClient.Hackney
end
