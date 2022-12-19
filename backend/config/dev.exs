import Config

config :azimutt,
  environment: :dev,
  domain: "localhost",
  site_url: "http://localhost:4000",
  support_email: "hey@azimutt.local",
  mailer_default_from_email: "hey@azimutt.dev",
  team_plan_price_id: "price_1LqdRzCaPXsf4vehSyyUn4pd"

config :cors_plug,
  origin: ["http://localhost:4001"],
  max_age: 86400

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :azimutt, AzimuttWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "pxuh3/ZPxBxB6KFcMRsSCy71yUZblPC/3eLTZcZnskkiTLfvxmY3V0cHXzmQUA8p",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :azimutt, AzimuttWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/azimutt_web/(live|views)/.*(ex)$",
      ~r"lib/azimutt_web/templates/.*(eex)$"
    ]
  ]

config :waffle, storage: Waffle.Storage.Local

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
