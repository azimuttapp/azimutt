import Config

config :azimutt, AzimuttWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :azimutt,
  environment: :staging,
  support_email: "hey@azimutt.dev",
  mailer_default_from_email: "hey@azimutt.dev",
  pro_plan_price_id: "price_1LqdRzCaPXsf4vehSyyUn4pd"

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
