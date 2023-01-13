defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
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
      heroku_count: Admin.count_heroku_resources()
    )
  end
end
