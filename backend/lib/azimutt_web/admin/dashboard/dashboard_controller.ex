defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    now = DateTime.utc_now()
    three_months_ago = DateTime.utc_now() |> Timex.shift(months: -3)
    one_year_ago = DateTime.utc_now() |> Timex.shift(months: -12)

    # The admin dashboard runs ~15 aggregates over the large `events` table. Running them
    # sequentially summed past the 15s DB pool timeout and /admin returned 500, so we run
    # them concurrently. Concurrency is bounded below the DB pool (pool_size 10) so other
    # requests still get a connection. Temporarily lightened: the 360-day monthly chart and
    # the "returning users" series are disabled (the heaviest count(distinct) scans).
    assigns =
      [
        users_count: fn -> Admin.count_users() end,
        projects_count: fn -> Admin.count_projects() end,
        organizations_count: fn -> Admin.count_non_personal_organizations() end,
        paid_count: fn -> Admin.count_paid_organizations() end,
        clever_cloud_count: fn -> Admin.count_clever_cloud_resources() end,
        heroku_count: fn -> Admin.count_heroku_resources() end,
        connected_chart: fn ->
          Dataset.chartjs_daily_data(
            [
              Admin.daily_connected_users() |> Dataset.from_values("Daily users")
              # Admin.daily_connected_users_returning() |> Dataset.from_values("Daily returning users")
            ],
            three_months_ago,
            now
          )
        end,
        weekly_connected_chart: fn ->
          Dataset.chartjs_weekly_data(
            [
              Admin.weekly_connected_users() |> Dataset.from_values("Weekly users")
              # Admin.weekly_connected_users_returning() |> Dataset.from_values("Weekly returning users")
            ],
            one_year_ago,
            now
          )
        end,
        # monthly_connected_chart temporarily disabled (360-day window is the heaviest query).
        # Re-enable here and in index.html.heex when needed:
        #   monthly_connected_chart: fn ->
        #     Dataset.chartjs_monthly_data([
        #       Admin.monthly_connected_users() |> Dataset.from_values("Monthly users"),
        #       Admin.monthly_connected_users_returning() |> Dataset.from_values("Monthly returning users")
        #     ])
        #   end,
        created_chart: fn ->
          Dataset.chartjs_daily_data(
            [
              Admin.daily_created_users() |> Dataset.from_values("Created users")
            ],
            three_months_ago,
            now
          )
        end,
        pro_events: fn ->
          Dataset.chartjs_daily_data(
            [
              Admin.daily_event("plan_limit") |> Dataset.from_values("plan_limit"),
              Admin.daily_event("billing_loaded") |> Dataset.from_values("billing_loaded"),
              Admin.daily_event("stripe_open_billing_portal") |> Dataset.from_values("open_billing_portal")
            ],
            three_months_ago,
            now
          )
        end,
        feature_events: fn ->
          Dataset.chartjs_daily_data(
            [
              Admin.daily_event("project_created") |> Dataset.from_values("project_created")
            ],
            three_months_ago,
            now
          )
        end,
        last_active_users: fn -> Admin.last_active_users(50) end,
        most_active_users: fn -> Admin.most_active_users(50) end,
        lost_active_users: fn -> Admin.lost_active_users(50) end,
        lost_users: fn -> Admin.lost_users(50) end,
        plan_limit_users: fn -> Admin.plan_limit_users(50) end,
        billing_loaded_users: fn -> Admin.billing_loaded_users(50) end
      ]
      |> Task.async_stream(fn {key, fun} -> {key, fun.()} end,
        max_concurrency: 8,
        timeout: 30_000,
        ordered: false
      )
      |> Enum.map(fn {:ok, key_value} -> key_value end)

    render(conn, "index.html", assigns)
  end
end
