defmodule AzimuttWeb.Api.HealthController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  action_fallback AzimuttWeb.Api.FallbackController

  def ping(conn, _params) do
    conn |> render("ping.json")
  end

  def health(conn, _params) do
    current_user = conn.assigns.current_user
    conn |> render("health.json", user: current_user)
  end
end
