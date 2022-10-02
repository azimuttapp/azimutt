defmodule AzimuttWeb.PageController do
  use AzimuttWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
