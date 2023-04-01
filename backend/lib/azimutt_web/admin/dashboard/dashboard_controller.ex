defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    now = DateTime.utc_now()
    page = conn |> Page.from_conn(%{search_on: Event.search_fields(), sort: "-created_at", size: 40})
    {:ok, start_stats} = "2022-12-01" |> Timex.parse("{YYYY}-{0M}-{0D}")

    conn
    |> render("index.html",
      events: Admin.list_events(page),
      users_count: Admin.count_users(),
      projects_count: Admin.count_projects(),
      organizations_count: Admin.count_non_personal_organizations(),
      stripe_count: Admin.count_stripe_subscriptions(),
      heroku_count: Admin.count_heroku_resources(),
      connected_chart:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_connected_users() |> Dataset.from_values("Daily users"),
            Admin.daily_used_projects() |> Dataset.from_values("Daily projects")
          ],
          start_stats,
          now
        ),
      weekly_connected_chart:
        Dataset.chartjs_weekly_data(
          [
            Admin.weekly_connected_users() |> Dataset.from_values("Weekly users"),
            Admin.weekly_used_projects() |> Dataset.from_values("Weekly projects")
          ],
          start_stats,
          now
        ),
      monthly_connected_chart:
        Dataset.chartjs_monthly_data(
          [
            Admin.monthly_connected_users() |> Dataset.from_values("Monthly users"),
            Admin.monthly_used_projects() |> Dataset.from_values("Monthly projects")
          ],
          start_stats,
          now
        ),
      created_chart:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_created_users() |> Dataset.from_values("Created users"),
            Admin.daily_created_projects() |> Dataset.from_values("Created projects"),
            Admin.daily_created_non_personal_organizations() |> Dataset.from_values("Created organizations")
          ],
          start_stats,
          now
        ),
      pro_events:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_event("plan_limit") |> Dataset.from_values("plan_limit"),
            Admin.daily_event("billing_loaded") |> Dataset.from_values("billing_loaded"),
            Admin.daily_event("stripe_open_billing_portal") |> Dataset.from_values("open_billing_portal")
          ],
          start_stats,
          now
        ),
      feature_events:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_event("user_login") |> Dataset.from_values("login"),
            Admin.daily_event("editor_project_draft_created") |> Dataset.from_values("project_draft_created"),
            Admin.daily_event("project_created") |> Dataset.from_values("project_created"),
            Admin.daily_event("editor_layout_created") |> Dataset.from_values("layout_created"),
            Admin.daily_event("editor_notes_created") |> Dataset.from_values("notes_created"),
            Admin.daily_event("editor_memo_created") |> Dataset.from_values("memo_created"),
            Admin.daily_event("editor_source_created") |> Dataset.from_values("source_created"),
            Admin.daily_event("editor_db_analysis_opened") |> Dataset.from_values("db_analysis_opened"),
            Admin.daily_event("editor_find_path_opened") |> Dataset.from_values("find_path_opened")
          ],
          start_stats,
          now
        )
    )
  end
end
