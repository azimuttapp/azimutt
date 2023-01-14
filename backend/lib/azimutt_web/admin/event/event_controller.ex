defmodule AzimuttWeb.Admin.EventController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html", events: Admin.list_events(conn |> Page.from_conn(%{size: 120})))
  end

  def show(conn, %{"id" => event_id}) do
    with {:ok, event} <- Admin.get_event(event_id) do
      conn |> render("show.html", event: event)
    end
  end
end
