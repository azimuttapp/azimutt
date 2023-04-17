import Config

config :azimutt, AzimuttWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

config :azimutt, AzimuttWeb.Endpoint,
  url: [host: "azimutt.dev", port: 80],
  check_origin: true
