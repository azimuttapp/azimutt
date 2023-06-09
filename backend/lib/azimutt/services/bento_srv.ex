defmodule Azimutt.Services.BentoSrv do
  @moduledoc false
  require Logger
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  # see https://docs.bentonow.com/batch-api/events
  def send_event(%Event{} = event) do
    bento_event = %{
      email: event.created_by.email,
      type: event.name,
      fields: %{},
      details:
        if event.details do
          event.details |> Map.put("instance", Azimutt.config(:host))
        else
          %{instance: Azimutt.config(:host)}
        end,
      date: event.created_at
    }

    HTTPoison.post(
      "https://app.bentonow.com/api/v1/batch/events",
      Jason.encode!(%{site_uuid: Azimutt.config(:bento_site_key), events: [bento_event]}),
      [{"Content-Type", "application/json"}],
      hackney: [basic_auth: {Azimutt.config(:bento_publishable_key), Azimutt.config(:bento_secret_key)}]
    )
    |> Result.flat_map(fn res -> Jason.decode(res.body) end)
    |> Result.tap_error(fn err -> Logger.error("BentoSrv.send_event: #{Stringx.inspect(err)}") end)
  end
end
