defmodule AzimuttWeb.Api.TrackingController do
  use AzimuttWeb, :controller
  alias Azimutt.Tracking
  alias Azimutt.Utils.Nil
  action_fallback AzimuttWeb.Api.FallbackController

  def create(conn, %{"name" => name} = params) do
    current_user = conn.assigns.current_user
    Tracking.frontend_event(name, params["details"], current_user, params["organization"], params["project"])
    conn |> send_resp(:no_content, "")
  end
end
