import Config

config :azimutt, AzimuttWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :azimutt,
  environment: :staging,
  domain: "azimutt.dev",
  site_url: "https://azimutt.dev",
  support_email: "hey@azimutt.dev",
  mailer_default_from_email: "hey@azimutt.dev"

# Do not print debug messages in production
config :logger, level: :info

config :sentry,
  dsn: "https://e9e1c774b12b459592c58405c6cf4102@o1353262.ingest.sentry.io/6635088",
  environment_name: :staging,
  release: Mix.Project.config()[:version],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "staging"
  },
  included_environments: [:staging]

config :azimutt, AzimuttWeb.Endpoint,
  url: [host: "azimutt.dev", port: 80],
  check_origin: true

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
