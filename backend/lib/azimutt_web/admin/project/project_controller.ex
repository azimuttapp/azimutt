defmodule AzimuttWeb.Admin.ProjectController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html", projects: Admin.list_projects(conn |> Page.from_conn()))
  end

  def show(conn, %{"id" => project_id}) do
    with {:ok, project} <- Admin.get_project(project_id) do
      conn
      |> render("show.html",
        project: project,
        events: Admin.get_project_events(project.id, conn |> Page.from_conn(%{prefix: "events", size: 40}))
      )
    end
  end
end
