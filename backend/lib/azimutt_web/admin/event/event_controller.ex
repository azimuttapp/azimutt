defmodule AzimuttWeb.Admin.EventController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def show(conn, %{"id" => event_id}) do
    with {:ok, event} <- Azimutt.Admin.get_event(event_id) do
      render(conn, "show.html", event: event)
    end
  end
end
