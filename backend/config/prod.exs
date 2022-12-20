import Config

config :azimutt, AzimuttWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :azimutt,
  environment: :prod,
  domain: System.get_env("PHX_HOST"),
  site_url: System.get_env("PHX_HOST"),
  support_email: "hey@azimutt.app",
  mailer_default_from_email: "hey@azimutt.app",
  team_plan_price_id: "price_1LqeMcCaPXsf4veh2yBgWKiX"

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
