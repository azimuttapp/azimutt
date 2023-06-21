defmodule AzimuttWeb.Admin.ProjectController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  alias Azimutt.Projects.Project
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    page = conn |> Page.from_conn(%{search_on: Project.search_fields(), sort: "-created_at"})
    conn |> render("index.html", projects: Admin.list_projects(page))
  end

  def show(conn, %{"project_id" => project_id}) do
    now = DateTime.utc_now()
    events_page = conn |> Page.from_conn(%{prefix: "events", search_on: Event.search_fields(), sort: "-created_at", size: 40})
    {:ok, start_stats} = "2022-11-01" |> Timex.parse("{YYYY}-{0M}-{0D}")

    with {:ok, project} <- Admin.get_project(project_id) do
      conn
      |> render("show.html",
        project: project,
        activity:
          Dataset.chartjs_daily_data([Admin.daily_project_activity(project) |> Dataset.from_values("Daily events")], start_stats, now),
        events: Admin.get_project_events(project, events_page)
      )
    end
  end
end
