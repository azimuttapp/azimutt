import Config

config :azimutt,
  environment: :prod,
  domain: "azimutt.app",
  site_url: "https://azimutt.app",
  support_email: "hey@azimutt.app",
  mailer_default_from_email: "hey@azimutt.app",
  team_plan_price_id: "price_1LqeMcCaPXsf4veh2yBgWKiX"

# Do not print debug messages in production
logger_level = System.get_env("LOGGER_LEVEL")
config :logger, level: if(logger_level, do: String.to_existing_atom(logger_level), else: :info)

config :azimutt, AzimuttWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  debug_errors: logger_level == "debug"

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

cellar_addon_key_id = System.get_env("CELLAR_ADDON_KEY_ID")
cellar_addon_key_secret = System.get_env("CELLAR_ADDON_KEY_SECRET")
cellar_host = System.get_env("CELLAR_ADDON_HOST")
cellar_bucket = System.get_env("CELLAR_BUCKET")

if cellar_addon_key_id && cellar_addon_key_secret && cellar_host && cellar_bucket do
  IO.puts("Setup Cellar storage")

  config :waffle,
    storage: Waffle.Storage.S3,
    asset_host: cellar_host,
    bucket: cellar_bucket

  config :ex_aws,
    debug_requests: true,
    json_codec: Jason,
    access_key_id: cellar_addon_key_id,
    secret_access_key: cellar_addon_key_secret

  config :ex_aws, :s3,
    scheme: "https://",
    host: cellar_host,
    region: "eu-west-1"
else
  raise "missing cellar environment variables: CELLAR_ADDON_KEY_ID, CELLAR_ADDON_KEY_SECRET, CELLAR_ADDON_HOST and CELLAR_BUCKET"
end

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
