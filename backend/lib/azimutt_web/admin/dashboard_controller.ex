defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    conn |> render("index.html")
  end
end
