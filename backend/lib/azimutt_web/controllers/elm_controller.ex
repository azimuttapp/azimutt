defmodule AzimuttWeb.ElmController do
  use AzimuttWeb, :controller

  # every action is the same, just load the Elm index but we need different actions for the reverse router
  def create(conn, _params), do: load_elm(conn)
  def embed(conn, _params), do: load_elm(conn)
  def last(conn, _params), do: load_elm(conn)
  def new(conn, _params), do: load_elm(conn)
  def projects_legacy(conn, _params), do: load_elm(conn)
  def orga_create(conn, _params), do: load_elm(conn)
  def orga_new(conn, _params), do: load_elm(conn)
  def project_show(conn, _params), do: load_elm(conn)

  defp load_elm(conn) do
    conn |> put_root_layout({AzimuttWeb.LayoutView, "elm.html"}) |> render("index.html")
  end
end
