# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :azimutt,
  business_name: "Azimutt",
  seo_title: "Azimutt · Database explorer and analyzer",
  seo_description: "Next-Gen ERD: explore, analyze, document and design your SQL database schema.",
  seo_keywords:
    "SQL,schema,database,entity relationship diagram,data analyst,schema explorer,schema analyzer,DDL,DBA,database schema,database diagram,explore,understand,visualization",
  mailer_default_from_name: "Support",
  logo_url_for_emails: "https://res.cloudinary.com/azimutt/image/upload/v1659696136/logo/logo_wtzb16.png",
  twitter_url: "https://twitter.com/azimuttapp",
  github_url: "https://github.com/azimuttapp/azimutt",
  github_new_issue: "https://github.com/azimuttapp/azimutt/issues/new",
  team_plan_price_id: "price_1LqdRzCaPXsf4vehSyyUn4pd",
  team_plan_seat_price: 13,
  free_plan_seats: 3,
  # MUST stay in sync with freePlanLayouts in frontend/src/Conf.elm
  free_plan_layouts: 3

config :azimutt,
  ecto_repos: [Azimutt.Repo]

config :azimutt, Azimutt.Repo, migration_primary_key: [type: :uuid]

config :azimutt, Azimutt.Repo, migration_timestamps: [type: :utc_datetime_usec, inserted_at: :created_at]

# Configures the endpoint
config :azimutt, AzimuttWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AzimuttWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Azimutt.PubSub,
  live_view: [signing_salt: "eIPt31PL"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :azimutt, Azimutt.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, true

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tailwind,
  version: "3.0.24",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user,public_repo,notifications"]}
  ]

config :azimutt, AzimuttWeb.Storybook,
  content_path: Path.expand("../lib/azimutt_web/storybook/", __DIR__),
  css_path: "/assets/app.css",
  js_path: "/assets/app.js",
  title: "Azimutt Storybook"

config :azimutt, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      # phoenix routes will be converted to swagger paths
      router: AzimuttWeb.Router,
      # (optional) endpoint config used to set host, port and https schemes.
      endpoint: AzimuttWeb.Endpoint
    ]
  }

config :waffle, storage: Waffle.Storage.Local

config :ex_aws, json_codec: Jason

config :phoenix_swagger, json_library: Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
