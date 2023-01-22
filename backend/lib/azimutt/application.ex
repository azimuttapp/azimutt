defmodule Azimutt.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  
  def env do
    Application.fetch_env!(:azimutt, :app_env)
  end

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Azimutt.Repo,
      # Start the Telemetry supervisor
      AzimuttWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Azimutt.PubSub},
      # Start the Endpoint (http/https)
      AzimuttWeb.Endpoint
      # Start a worker by calling: Azimutt.Worker.start_link(arg)
      # {Azimutt.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Azimutt.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AzimuttWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
