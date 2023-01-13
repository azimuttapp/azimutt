defmodule AzimuttWeb.Admin.ProjectController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html", projects: Admin.list_projects(1000))
  end

  def show(conn, %{"id" => project_id}) do
    with {:ok, project} <- Admin.get_project(project_id) do
      conn
      |> render("show.html",
        project: project,
        events: Admin.get_project_events(project.id, 1000)
      )
    end
  end
end
