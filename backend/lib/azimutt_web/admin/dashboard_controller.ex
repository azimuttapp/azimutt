defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    events = Azimutt.Admin.list_last_events(20)
    conn |> render("index.html", events: events)
  end
end
