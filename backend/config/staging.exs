import Config

config :azimutt, AzimuttWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :azimutt,
  environment: :staging,
  domain: "azimutt.dev",
  site_url: "https://azimutt.dev",
  support_email: "hey@azimutt.dev",
  mailer_default_from_email: "hey@azimutt.dev",
  team_plan_price_id: "price_1LqdRzCaPXsf4vehSyyUn4pd"

# Do not print debug messages in staging
config :logger, level: :debug

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
  debug_errors: true,
  check_origin: true

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
