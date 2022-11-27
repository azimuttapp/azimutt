defmodule AzimuttWeb.ElmController do
  use AzimuttWeb, :controller
  alias Azimutt.Audit
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  action_fallback AzimuttWeb.FallbackController

  # every action is the same, just load the Elm index but we need different actions for the reverse router
  def create(conn, _params), do: conn |> load_elm
  def embed(conn, _params), do: conn |> load_elm
  def last(conn, _params), do: conn |> load_elm
  def new(conn, _params), do: conn |> load_elm
  def projects_legacy(conn, _params), do: conn |> load_elm
  def orga_create(conn, _params), do: conn |> load_elm
  def orga_new(conn, _params), do: conn |> load_elm

  def orga_show(conn, %{"organization_id" => organization_id}) do
    if organization_id |> String.length() == 36 do
      conn |> redirect(to: Routes.organization_path(conn, :show, organization_id))
    else
      {:error, :not_found}
    end
  end

  def project_show(conn, %{"organization_id" => organization_id, "project_id" => project_id}) do
    current_user = conn.assigns.current_user

    if project_id |> String.length() == 36 do
      # TODO: uncomment in 2023 when legacy projects are not supported anymore
      # with {:ok, %Project{} = _project} <- Projects.get_project(project_id, conn.assigns.current_user),
      #      do: conn |> load_elm
      with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
           do: Audit.project_loaded(current_user, organization_id, project_id)

      conn |> load_elm
    else
      {:error, :not_found}
    end
  end

  defp load_elm(conn) do
    conn |> put_root_layout({AzimuttWeb.LayoutView, "elm.html"}) |> render("index.html")
  end
end
