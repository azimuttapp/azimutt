defmodule AzimuttWeb.Admin.DashboardController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    events = Azimutt.Admin.list_last_events()
    organizations = Azimutt.Admin.list_organizations()
    users = Azimutt.Admin.list_users()
    projects = Azimutt.Admin.list_projects()

    organizations_count =
      organizations
      |> Enum.filter(fn organization -> organization.is_personal == false end)
      |> Enum.count()

    subscriptions_count =
      organizations
      |> Enum.filter(fn organization -> organization.stripe_subscription_id !== nil end)
      |> Enum.count()

    projects_count =
      projects
      |> Enum.count()

    users_count =
      users
      |> Enum.count()

    conn
    |> render(
      "index.html",
      events: events,
      organizations: organizations,
      projects_count: projects_count,
      organizations_count: organizations_count,
      subscriptions_count: subscriptions_count,
      users_count: users_count
    )
  end
end
