defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    conn
    |> render(
      "index.html",
      events: Admin.list_events(50),
      users_count: Admin.count_users(),
      projects_count: Admin.count_projects(),
      organizations_count: Admin.count_non_personal_organizations(),
      stripe_count: Admin.count_stripe_subscriptions(),
      heroku_count: Admin.count_heroku_resources(),
      created_chart:
        Dataset.chartjs_daily_data([
          Admin.daily_created_users() |> Dataset.from_values("Created users"),
          Admin.daily_created_projects() |> Dataset.from_values("Created projects"),
          Admin.daily_created_non_personal_organizations() |> Dataset.from_values("Created organizations")
        ]),
      connected_chart:
        Dataset.chartjs_daily_data([
          Admin.daily_connected_users() |> Dataset.from_values("Daily users"),
          Admin.daily_used_projects() |> Dataset.from_values("Daily projects")
        ]),
      monthly_connected_chart:
        Dataset.chartjs_monthly_data([
          Admin.monthly_connected_users() |> Dataset.from_values("Monthly users"),
          Admin.monthly_used_projects() |> Dataset.from_values("Monthly projects")
        ])
    )
  end
end
