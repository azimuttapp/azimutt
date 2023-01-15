defmodule AzimuttWeb.Admin.ProjectController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    conn
    |> render("index.html",
      projects: Admin.list_projects(conn |> Page.from_conn(%{sort: "-created_at"}))
    )
  end

  def show(conn, %{"id" => project_id}) do
    with {:ok, project} <- Admin.get_project(project_id) do
      conn
      |> render("show.html",
        project: project,
        activity: Dataset.chartjs_daily_data([Admin.daily_project_activity(project) |> Dataset.from_values("Daily events")]),
        events: Admin.get_project_events(project, conn |> Page.from_conn(%{prefix: "events", sort: "-created_at", size: 40}))
      )
    end
  end
end
