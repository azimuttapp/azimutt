defmodule Azimutt.Services.PostHogSrv do
  @moduledoc false
  require Logger

  # see https://posthog.com/docs/libraries/elixir
  def send_event(event) do
    if event.created_by do
      Posthog.capture(event.name, %{
        distinct_id: event.created_by.id,
        email: event.created_by.email
      })
    else
      Posthog.capture(event.name, %{})
    end

    # |> Result.tap_error(fn err -> Logger.error("PostHogSrv.send_event: #{Stringx.inspect(err)}") end)
  end
end
