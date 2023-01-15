defmodule AzimuttWeb.Admin.UserController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    conn
    |> render("index.html",
      users: Admin.list_users(conn |> Page.from_conn(%{sort: "-created_at"}))
    )
  end

  def show(conn, %{"id" => user_id}) do
    with {:ok, user} <- Admin.get_user(user_id) do
      conn
      |> render("show.html",
        user: user,
        organizations: user.organizations |> Page.wrap(),
        projects: user.organizations |> Enum.flat_map(fn o -> o.projects end) |> Page.wrap(),
        activity: Dataset.chartjs_daily_data([Admin.daily_user_activity(user) |> Dataset.from_values("Daily events")]),
        events: Admin.get_user_events(user, conn |> Page.from_conn(%{prefix: "events", sort: "-created_at", size: 40}))
      )
    end
  end
end
