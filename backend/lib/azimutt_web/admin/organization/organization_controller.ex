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
    now = DateTime.utc_now()

    with {:ok, organization} <- Admin.get_organization(organization_id) do
      conn
      |> render("show.html",
        now: now,
        organization: organization,
        projects: organization.projects |> Enum.sort_by(& &1.updated_at, {:desc, Date}) |> Page.wrap(),
        members: organization.members |> Enum.sort_by(& &1.created_at, {:desc, Date}) |> Enum.map(fn m -> m.user end) |> Page.wrap(),
        invitations: organization.invitations |> Enum.sort_by(& &1.created_at, {:desc, Date}) |> Page.wrap(),
        activity: Dataset.chartjs_daily_data([Admin.daily_organization_activity(organization) |> Dataset.from_values("Daily events")]),
        events: Admin.get_organization_events(organization, conn |> Page.from_conn(%{prefix: "events", sort: "-created_at", size: 40}))
      )
    end
  end
end
