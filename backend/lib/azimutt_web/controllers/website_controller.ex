defmodule AzimuttWeb.WebsiteController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
