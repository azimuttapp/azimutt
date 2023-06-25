defmodule Azimutt.Services.CockpitSrv do
  @moduledoc false
  require Logger
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  def send_event(%Event{} = event) do
    user =
      if event.created_by do
        %{
          user: %{
            id: event.created_by.id,
            name: event.created_by.name,
            email: event.created_by.email
          }
        }
      else
        %{}
      end

    cockpit_event = %{
      id: event.id,
      instance: Azimutt.config(:host),
      name: event.name,
      details: Map.merge(event.details || %{}, user),
      createdAt: event.created_at
    }

    HTTPoison.post(
      "https://cockpit.azimutt.app/api/events",
      Jason.encode!(cockpit_event),
      [{"Content-Type", "application/json"}]
    )
    |> Result.flat_map(fn res -> Jason.decode(res.body) end)
    |> Result.tap_error(fn err -> Logger.error("CockpitSrv.send_event: #{Stringx.inspect(err)}") end)
  end
end
