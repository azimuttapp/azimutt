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

  def show(conn, %{"id" => user_id}) do
    events_page = conn |> Page.from_conn(%{prefix: "events", search_on: Event.search_fields(), sort: "-created_at", size: 40})

    with {:ok, user} <- Admin.get_user(user_id) do
      conn
      |> render("show.html",
        user: user,
        organizations: user.organizations |> Page.wrap(),
        projects: user.organizations |> Enum.flat_map(fn o -> o.projects end) |> Page.wrap(),
        activity: Dataset.chartjs_daily_data([Admin.daily_user_activity(user) |> Dataset.from_values("Daily events")]),
        events: Admin.get_user_events(user, events_page)
      )
    end
  end
end
