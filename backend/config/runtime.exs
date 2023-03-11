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

if config_env() != :test do
  config :azimutt,
    domain: System.fetch_env!("PHX_HOST")
end

skip_public_site = System.get_env("SKIP_PUBLIC_SITE") == "true"
global_organization = System.get_env("GLOBAL_ORGANIZATION")
global_organization_alone = global_organization && System.get_env("GLOBAL_ORGANIZATION_ALONE") == "true"

config :azimutt,
  skip_public_site: skip_public_site,
  global_organization: global_organization,
  global_organization_alone: global_organization_alone

if config_env() == :prod || config_env() == :staging do
  database_url =
    System.get_env("DATABASE_URL") || raise "environment variable DATABASE_URL is missing. Expecting: ecto://USER:PASS@HOST/DATABASE"

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
      raise "environment variable SECRET_KEY_BASE is missing. You can generate one by calling: mix phx.gen.secret"

  host = System.fetch_env!("PHX_HOST")
  port = String.to_integer(System.fetch_env!("PORT"))

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
end

file_storage_adapter = System.fetch_env!("FILE_STORAGE_ADAPTER")

cond do
  file_storage_adapter == "local" ->
    IO.puts("Setup Local file storage")
    config :waffle, storage: Waffle.Storage.Local
    config :ex_aws, json_codec: Jason

  file_storage_adapter == "s3" ->
    IO.puts("Setup S3 file storage")
    s3_host = System.get_env("S3_HOST")
    s3_key_id = System.get_env("S3_KEY_ID")
    s3_key_secret = System.get_env("S3_KEY_SECRET")
    s3_bucket = System.fetch_env!("S3_BUCKET")

    # https://hexdocs.pm/waffle/Waffle.Storage.S3.html
    if s3_host != nil && s3_host != '' do
      config :waffle,
        storage: Waffle.Storage.S3,
        bucket: s3_bucket,
        asset_host: s3_host

      config :ex_aws, :s3,
        scheme: "https://",
        host: s3_host,
        region: "eu-west-1"
    else
      config :waffle,
        storage: Waffle.Storage.S3,
        bucket: s3_bucket
    end

    if s3_key_id != nil && s3_key_id != '' && s3_key_secret != nil && s3_key_secret != '' do
      config :ex_aws,
        debug_requests: true,
        json_codec: Jason,
        access_key_id: s3_key_id,
        secret_access_key: s3_key_secret
    end

  true ->
    raise "unknown FILE_STORAGE_ADAPTER '#{file_storage_adapter}'"
end

email_adapter = System.get_env("EMAIL_ADAPTER")

cond do
  email_adapter == "mailgun" ->
    IO.puts("Setup Mailgun email provider")
    mailgun_api_key = System.get_env("MAILGUN_API_KEY")
    mailgun_domain = System.get_env("MAILGUN_DOMAIN")
    mailgun_base_url = System.get_env("MAILGUN_BASE_URL")

    if mailgun_api_key && mailgun_domain && mailgun_base_url do
      # https://hexdocs.pm/swoosh/Swoosh.Adapters.Mailgun.html
      config :azimutt, Azimutt.Mailer,
        adapter: Swoosh.Adapters.Mailgun,
        api_key: mailgun_api_key,
        domain: mailgun_domain,
        base_url: mailgun_base_url
    else
      raise "missing Mailgun environment variables: MAILGUN_API_KEY, MAILGUN_DOMAIN and MAILGUN_BASE_URL"
    end

  email_adapter == "gmail" ->
    IO.puts("Setup Gmail email provider")
    gmail_access_token = System.get_env("GMAIL_ACCESS_TOKEN")

    if gmail_access_token do
      # https://hexdocs.pm/swoosh/Swoosh.Adapters.Gmail.html
      config :azimutt, Azimutt.Mailer,
        adapter: Swoosh.Adapters.Gmail,
        access_token: gmail_access_token
    else
      raise "missing Gmail environment variable: GMAIL_ACCESS_TOKEN"
    end

  true ->
    IO.puts("Email system not setup (EMAIL_ADAPTER env variable not found)")
end

config :swoosh, :api_client, Swoosh.ApiClient.Hackney

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

# https://dashboard.stripe.com/test/apikeys & https://dashboard.stripe.com/account/webhooks
stripe_api_key = System.get_env("STRIPE_API_KEY")
stripe_webhook_key = System.get_env("STRIPE_WEBHOOK_SIGNING_SECRET")

if stripe_api_key && stripe_webhook_key do
  IO.puts("Setup Stripe")

  config :stripity_stripe,
    api_key: stripe_api_key,
    signing_secret: stripe_webhook_key
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
end

bento_site_key = System.get_env("BENTO_SITE_KEY")
bento_publishable_key = System.get_env("BENTO_PUBLISHABLE_KEY")
bento_secret_key = System.get_env("BENTO_SECRET_KEY")

if bento_site_key && bento_publishable_key && bento_secret_key do
  IO.puts("Setup Bento integration")

  config :azimutt,
    bento_site_key: bento_site_key,
    bento_publishable_key: bento_publishable_key,
    bento_secret_key: bento_secret_key
end

twitter_consumer_key = System.get_env("TWITTER_CONSUMER_KEY")
twitter_consumer_secret = System.get_env("TWITTER_CONSUMER_SECRET")
twitter_access_token = System.get_env("TWITTER_ACCESS_TOKEN")
twitter_access_token_secret = System.get_env("TWITTER_ACCESS_SECRET")

if twitter_consumer_key && twitter_consumer_secret && twitter_access_token && twitter_access_token_secret do
  IO.puts("Setup Twitter integration")

  config :extwitter, :oauth,
    consumer_key: twitter_consumer_key,
    consumer_secret: twitter_consumer_secret,
    access_token: twitter_access_token,
    access_token_secret: twitter_access_token_secret
end

github_access_token = System.get_env("GITHUB_ACCESS_TOKEN")

if github_access_token do
  IO.puts("Setup Github integration")

  config :azimutt,
    github_access_token: github_access_token
end
