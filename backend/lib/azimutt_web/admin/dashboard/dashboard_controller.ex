defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    now = DateTime.utc_now()
    three_months_ago = DateTime.utc_now() |> Timex.shift(months: -3)
    one_year_ago = DateTime.utc_now() |> Timex.shift(months: -12)

    conn
    |> render("index.html",
      users_count: Admin.count_users(),
      projects_count: Admin.count_projects(),
      organizations_count: Admin.count_non_personal_organizations(),
      stripe_count: Admin.count_stripe_subscriptions(),
      clever_cloud_count: Admin.count_clever_cloud_resources(),
      heroku_count: Admin.count_heroku_resources(),
      connected_chart:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_connected_users() |> Dataset.from_values("Daily users"),
            Admin.daily_used_projects() |> Dataset.from_values("Daily projects")
          ],
          three_months_ago,
          now
        ),
      weekly_connected_chart:
        Dataset.chartjs_weekly_data(
          [
            Admin.weekly_connected_users() |> Dataset.from_values("Weekly users"),
            Admin.weekly_used_projects() |> Dataset.from_values("Weekly projects")
          ],
          one_year_ago,
          now
        ),
      monthly_connected_chart:
        Dataset.chartjs_monthly_data([
          Admin.monthly_connected_users() |> Dataset.from_values("Monthly users"),
          Admin.monthly_used_projects() |> Dataset.from_values("Monthly projects")
        ]),
      created_chart:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_created_users() |> Dataset.from_values("Created users"),
            Admin.daily_created_projects() |> Dataset.from_values("Created projects"),
            Admin.daily_created_non_personal_organizations() |> Dataset.from_values("Created organizations")
          ],
          three_months_ago,
          now
        ),
      pro_events:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_event("plan_limit") |> Dataset.from_values("plan_limit"),
            Admin.daily_event("billing_loaded") |> Dataset.from_values("billing_loaded"),
            Admin.daily_event("stripe_open_billing_portal") |> Dataset.from_values("open_billing_portal")
          ],
          three_months_ago,
          now
        ),
      feature_events:
        Dataset.chartjs_daily_data(
          [
            Admin.daily_event("user_login") |> Dataset.from_values("login")
            # Admin.daily_event("editor_project_draft_created") |> Dataset.from_values("project_draft_created"),
            # Admin.daily_event("project_created") |> Dataset.from_values("project_created"),
            # Admin.daily_event("editor_layout_created") |> Dataset.from_values("layout_created"),
            # Admin.daily_event("editor_notes_created") |> Dataset.from_values("notes_created"),
            # Admin.daily_event("editor_memo_created") |> Dataset.from_values("memo_created"),
            # Admin.daily_event("editor_source_created") |> Dataset.from_values("source_created"),
            # Admin.daily_event("editor_db_analysis_opened") |> Dataset.from_values("db_analysis_opened"),
            # Admin.daily_event("editor_find_path_opened") |> Dataset.from_values("find_path_opened")
          ],
          three_months_ago,
          now
        ),
      last_active_users: Admin.last_active_users(50),
      most_active_users: Admin.most_active_users(50),
      lost_active_users: Admin.lost_active_users(50),
      lost_users: Admin.lost_users(50),
      plan_limit_users: Admin.plan_limit_users(50),
      billing_loaded_users: Admin.billing_loaded_users(50)
    )
  end
end
