defmodule AzimuttWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :azimutt

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_azimutt_key",
    signing_salt: "9EWvUx5K",
    domain: Azimutt.config(:domain)
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :azimutt,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt elm blog)

  plug Plug.Static, at: "/uploads", from: Path.expand('./uploads'), gzip: false

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :azimutt
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Since Plug.Parsers removes the raw request_body in body_parsers
  # we need to parse out the Stripe webhooks before this
  plug Stripe.WebhookPlug,
    at: "/webhook/stripe",
    handler: Azimutt.StripeHandler,
    secret: {Application, :get_env, [:stripity_stripe, :signing_secret]}

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug AzimuttWeb.Router
  use Sentry.PlugCapture
end
