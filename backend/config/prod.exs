import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :azimutt, AzimuttWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :azimutt,
  environment: :prod,
  domain: "azimutt.app",
  site_url: "https://azimutt.app",
  support_email: "hey@azimutt.app",
  mailer_default_from_email: "hey@azimutt.app"

# Do not print debug messages in production
config :logger, level: :info

config :sentry,
  dsn: "https://e9e1c774b12b459592c58405c6cf4102@o1353262.ingest.sentry.io/6635088",
  environment_name: :prod,
  release: Mix.Project.config()[:version],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production"
  },
  included_environments: [:prod]

cellar_bucket =
  System.get_env("CELLAR_BUCKET") ||
    raise """
    environment variable CELLAR_BUCKET is missing.
    """

cellar_host =
  System.get_env("CELLAR_ADDON_HOST") ||
    raise """
    environment variable CELLAR_ADDON_HOST is missing.
    """

config :waffle,
  storage: Waffle.Storage.S3,
  bucket: cellar_bucket,
  asset_host: cellar_host

cellar_addon_key_id =
  System.get_env("CELLAR_ADDON_KEY_ID") ||
    raise """
    environment variable CELLAR_ADDON_KEY_ID is missing.
    """

cellar_addon_key_secret =
  System.get_env("CELLAR_ADDON_KEY_SECRET") ||
    raise """
    environment variable CELLAR_ADDON_KEY_SECRET is missing.
    """

config :ex_aws,
  debug_requests: true,
  json_codec: Jason,
  access_key_id: cellar_addon_key_id,
  secret_access_key: cellar_addon_key_secret

config :ex_aws, :s3,
  scheme: "https://",
  host: cellar_host,
  region: "eu-west-1"

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :azimutt, AzimuttWeb.Endpoint,
#       ...,
#       url: [host: "example.com", port: 443],
#       https: [
#         ...,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :azimutt, AzimuttWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.
