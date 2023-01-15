defmodule AzimuttWeb.Admin.OrganizationController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    conn
    |> render("index.html",
      organizations: Admin.list_organizations(conn |> Page.from_conn(%{sort: "-created_at"}))
    )
  end

  def show(conn, %{"id" => organization_id}) do
    with {:ok, organization} <- Admin.get_organization(organization_id) do
      conn
      |> render("show.html",
        organization: organization,
        members: organization.members |> Enum.map(fn m -> m.user end) |> Page.wrap(),
        projects: organization.projects |> Page.wrap(),
        activity: Dataset.chartjs_daily_data([Admin.daily_organization_activity(organization) |> Dataset.from_values("Daily events")]),
        events: Admin.get_organization_events(organization, conn |> Page.from_conn(%{prefix: "events", sort: "-created_at", size: 40}))
      )
    end
  end
end
