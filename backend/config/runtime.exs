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

stripe_api_key =
  System.get_env("STRIPE_API_KEY") ||
    raise """
    environment variable STRIPE_API_KEY is missing.
    You can obtain it from the stripe dashboard: https://dashboard.stripe.com/test/apikeys
    """

stripe_webhook_key =
  System.get_env("STRIPE_WEBHOOK_SIGNING_SECRET") ||
    raise """
    environment variable STRIPE_WEBHOOK_SIGNING_SECRET is missing.
    You can obtain it from the stripe dashboard: https://dashboard.stripe.com/account/webhooks
    """

config :azimutt,
  stripe_api_key: stripe_api_key

config :stripity_stripe,
  api_key: stripe_api_key,
  signing_secret: stripe_webhook_key

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id:
    System.get_env("GITHUB_CLIENT_ID") ||
      raise("""
      environment variable GITHUB_CLIENT_ID is missing.
      """),
  client_secret:
    System.get_env("GITHUB_CLIENT_SECRET") ||
      raise("""
      environment variable GITHUB_CLIENT_SECRET is missing.
      """)

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

  host = System.get_env("PHX_HOST") || "azimutt.app"
  port = String.to_integer(System.get_env("PORT") || "8080")

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

  mailgun_api_key =
    System.get_env("MAILGUN_API_KEY") ||
      raise """
      environment variable MAILGUN_API_KEY is missing.
      """

  mailgun_domain =
    System.get_env("MAILGUN_DOMAIN") ||
      raise """
      environment variable MAILGUN_DOMAIN is missing.
      """

  mailgun_base_url =
    System.get_env("MAILGUN_BASE_URL") ||
      raise """
      environment variable MAILGUN_BASE_URL is missing.
      """

  config :azimutt, Azimutt.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: mailgun_api_key,
    domain: mailgun_domain,
    base_url: mailgun_base_url

  config :swoosh, :api_client, Swoosh.ApiClient.Hackney
end
