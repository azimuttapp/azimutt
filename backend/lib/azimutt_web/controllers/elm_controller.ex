defmodule AzimuttWeb.ElmController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  # every action is the same, just load the Elm index but we need different actions for the reverse router
  def create(conn, _params), do: load_elm(conn)
  def embed(conn, _params), do: load_elm(conn)
  def last(conn, _params), do: load_elm(conn)
  def new(conn, _params), do: load_elm(conn)
  def projects_legacy(conn, _params), do: load_elm(conn)
  def orga_create(conn, _params), do: load_elm(conn)
  def orga_new(conn, _params), do: load_elm(conn)
  def project_show(conn, _params), do: load_elm(conn)

  def orga_show(conn, %{"organization_id" => organization_id}) do
    if organization_id |> String.length() == 36 do
      redirect(conn, to: Routes.organization_path(conn, :show, organization_id))
    else
      {:error, :not_found}
    end
  end

  defp load_elm(conn) do
    conn |> put_root_layout({AzimuttWeb.LayoutView, "elm.html"}) |> render("index.html")
  end
end
