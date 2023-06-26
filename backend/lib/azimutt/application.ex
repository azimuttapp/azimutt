defmodule Azimutt.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application
  alias Azimutt.Admin
  alias Azimutt.Services.CockpitSrv
  alias Azimutt.Utils.Uuid

  def env do
    Application.fetch_env!(:azimutt, :environment)
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
    res = Supervisor.start_link(children, opts)

    check_global_organization()
    CockpitSrv.boot_check()

    res
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AzimuttWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp check_global_organization do
    if Azimutt.config(:global_organization) do
      if !Uuid.is_valid?(Azimutt.config(:global_organization)) do
        raise "Configuration error: GLOBAL_ORGANIZATION '#{Azimutt.config(:global_organization)}' is not a valid UUID. Can't start."
      end

      alone = if(Azimutt.config(:global_organization_alone), do: " alone", else: "")

      case Admin.get_organization(Azimutt.config(:global_organization)) do
        {:ok, orga} -> IO.puts("Setup global organization#{alone}: #{orga.name} (#{orga.id})")
        _ -> raise "Configuration error: GLOBAL_ORGANIZATION '#{Azimutt.config(:global_organization)}' does not exist. Can't start."
      end
    end
  end
end
