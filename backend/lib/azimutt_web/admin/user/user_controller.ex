defmodule AzimuttWeb.Admin.UserController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts.User
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    page = conn |> Page.from_conn(%{search_on: User.search_fields(), sort: "-created_at"})
    conn |> render("index.html", users: Admin.list_users(page))
  end

  def show(conn, %{"user_id" => user_id}) do
    now = DateTime.utc_now()
    events_page = conn |> Page.from_conn(%{prefix: "events", search_on: Event.search_fields(), sort: "-created_at", size: 40})
    {:ok, start_stats} = "2022-11-01" |> Timex.parse("{YYYY}-{0M}-{0D}")

    with {:ok, user} <- Admin.get_user(user_id) do
      organizations = user.members |> Enum.map(fn m -> m.organization end)

      conn
      |> render("show.html",
        user: user,
        organizations: organizations |> Page.wrap(),
        projects: organizations |> Enum.flat_map(fn o -> o.projects end) |> Page.wrap(),
        activity: Dataset.chartjs_daily_data([Admin.daily_user_activity(user) |> Dataset.from_values("Daily events")], start_stats, now),
        events: Admin.get_user_events(user, events_page)
      )
    end
  end
end
