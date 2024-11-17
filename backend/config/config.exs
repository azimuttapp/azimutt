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
  seo_description: "Next-Gen ERD: Design, Explore, Document and Analyze your database.",
  seo_keywords: "SQL,schema,database,entity relationship diagram,data analyst,schema explorer,schema analyzer,DDL,DBA,database schema,database diagram,explore,understand,visualization",
  mailer_default_from_name: "Support",
  logo_url_for_emails: "https://azimutt.app/android-chrome-512x512.png",
  cli_url: "https://www.npmjs.com/package/azimutt",
  heroku_url: "https://elements.heroku.com/addons/azimutt",
  browser_extension_url: "https://chrome.google.com/webstore/detail/azimutt/bpifdkechgdibghkkpaioccoijeoebjf",
  azimutt_documentation: "https://azimutt.app/docs",
  azimutt_email: "contact@azimutt.app",
  azimutt_twitter: "https://twitter.com/azimuttapp",
  azimutt_linkedin: "https://www.linkedin.com/company/azimuttapp",
  azimutt_slack: "https://join.slack.com/t/azimutt/shared_invite/zt-1pumru3pj-iBKIq7f~7ADOfySuxuFA2Q",
  azimutt_github: "https://github.com/azimuttapp/azimutt",
  azimutt_github_issues: "https://github.com/azimuttapp/azimutt/issues",
  azimutt_github_issues_new: "https://github.com/azimuttapp/azimutt/issues/new",
  environment: config_env(),
  # TODO: find an automated process to build it
  version: "2.1.14",
  version_date: "2024-11-17T00:00:00.000Z",
  commit_hash: System.cmd("git", ["log", "-1", "--pretty=format:%h"]) |> elem(0) |> String.trim(),
  commit_message: System.cmd("git", ["log", "-1", "--pretty=format:%s"]) |> elem(0) |> String.trim(),
  commit_date: System.cmd("git", ["log", "-1", "--pretty=format:%aI"]) |> elem(0) |> String.trim(),
  commit_author: System.cmd("git", ["log", "-1", "--pretty=format:%an"]) |> elem(0) |> String.trim()

config :azimutt,
  ecto_repos: [Azimutt.Repo]

config :azimutt, Azimutt.Repo,
  migration_primary_key: [type: :uuid],
  migration_timestamps: [type: :utc_datetime_usec, inserted_at: :created_at]

# Configures the endpoint
config :azimutt, AzimuttWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AzimuttWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Azimutt.PubSub,
  live_view: [signing_salt: "eIPt31PL"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.23.1",
  default: [
    args: ~w(js/app.ts --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --loader:.ttf=file),
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
    # see https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps
    github: {Ueberauth.Strategy.Github, [default_scope: "read:user,user:email"]}
  ]

config :azimutt, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      # phoenix routes will be converted to swagger paths
      router: AzimuttWeb.Router,
      # (optional) endpoint config used to set host, port and https schemes.
      endpoint: AzimuttWeb.Endpoint
    ]
  }

config :phoenix_swagger, json_library: Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
