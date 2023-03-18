defmodule Azimutt.Services.BentoSrv do
  @moduledoc false
  alias Azimutt.Utils.Result

  # see https://docs.bentonow.com/batch-api/events
  def send_event(event) do
    HTTPoison.post(
      "https://app.bentonow.com/api/v1/batch/events",
      Jason.encode!(%{site_uuid: Azimutt.config(:bento_site_key), events: [event]}),
      [{"Content-Type", "application/json"}],
      hackney: [basic_auth: {Azimutt.config(:bento_publishable_key), Azimutt.config(:bento_secret_key)}]
    )
    |> Result.flat_map(fn res -> Jason.decode(res.body) end)
    |> Result.tap_error(fn err -> Logger.error("BentoSrv.send_event: #{Stringx.inspect(err)}") end)
  end
end
