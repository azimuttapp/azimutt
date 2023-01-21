defmodule AzimuttWeb.Admin.EventController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    page = conn |> Page.from_conn(%{search_on: Event.search_fields(), sort: "-created_at", size: 120})
    conn |> render("index.html", events: Admin.list_events(page))
  end

  def show(conn, %{"id" => event_id}) do
    events_page = conn |> Page.from_conn(%{prefix: "events", search_on: Event.search_fields(), sort: "-created_at", size: 120})

    with {:ok, event} <- Admin.get_event(event_id) do
      conn
      |> render("show.html",
        event: event,
        events: Admin.get_day_user_events(event.created_by, event.created_at, events_page)
      )
    end
  end
end
