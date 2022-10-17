defmodule AzimuttWeb.Api.UserController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  action_fallback AzimuttWeb.Api.FallbackController

  def current(conn, _params) do
    current_user = conn.assigns.current_user
    conn |> render("show.json", user: current_user)
  end
end
