defmodule AzimuttWeb.Admin.EventController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    events = Azimutt.Admin.list_last_events()

    render(conn, "index.html", events: events)
  end

  def show(conn, %{"id" => event_id}) do
    with {:ok, event} <- Azimutt.Admin.get_event(event_id) do
      render(conn, "show.html", event: event)
    end
  end
end
