defmodule AzimuttWeb.ElmController do
  use AzimuttWeb, :controller
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Tracking
  action_fallback AzimuttWeb.FallbackController

  # every action is the same, just load the Elm index but we need different actions for the reverse router
  def create(conn, _params), do: conn |> load_elm
  def embed(conn, _params), do: conn |> load_elm
  def new(conn, _params), do: conn |> load_elm
  def orga_create(conn, _params), do: conn |> load_elm
  def orga_new(conn, _params), do: conn |> load_elm

  def orga_show(conn, %{"organization_id" => organization_id}) do
    if organization_id |> String.length() == 36 do
      conn |> redirect(to: Routes.organization_path(conn, :show, organization_id))
    else
      {:error, :not_found}
    end
  end

  def project_show(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user

    if project_id |> String.length() == 36 do
      with {:ok, %Project{} = project} <- Projects.load_project(project_id, current_user, params["token"], now) do
        Tracking.project_loaded(current_user, project)
        conn |> load_elm
      end
    else
      {:error, :not_found}
    end
  end

  defp load_elm(conn) do
    conn |> put_root_layout({AzimuttWeb.LayoutView, "elm.html"}) |> render("index.html")
  end
end
