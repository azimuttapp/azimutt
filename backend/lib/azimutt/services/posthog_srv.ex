defmodule Azimutt.Services.PostHogSrv do
  @moduledoc false
  require Logger
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  # see https://posthog.com/docs/libraries/elixir
  def send_event(%Event{} = event) do
    PostHog.capture(
      event.name,
      distinct_id: event.created_by.id,
      name: event.created_by.name,
      email: event.created_by.email,
      organization_id: event.organization_id,
      project_id: event.project_id,
      details: event.details
    )
    |> Result.tap_error(fn err -> Logger.error("PostHogSrv.send_event: #{Stringx.inspect(err)}") end)
  end
end
