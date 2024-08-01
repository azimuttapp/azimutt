defmodule AzimuttWeb.Admin.OrganizationController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  alias Azimutt.Admin.Dataset
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationPlan
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Page
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    page = conn |> Page.from_conn(%{search_on: Organization.search_fields(), sort: "-created_at"})
    conn |> render("index.html", organizations: Admin.list_organizations(page))
  end

  def show(conn, %{"organization_id" => organization_id}) do
    now = DateTime.utc_now()
    events_page = conn |> Page.from_conn(%{prefix: "events", search_on: Event.search_fields(), sort: "-created_at", size: 40})
    {:ok, start_stats} = "2022-11-01" |> Timex.parse("{YYYY}-{0M}-{0D}")

    with {:ok, %Organization{} = organization} <- Admin.get_organization(organization_id),
         {:ok, %OrganizationPlan{} = plan} <- Organizations.get_organization_plan(organization, nil) do
      conn
      |> render("show.html",
        now: now,
        organization: organization,
        plan: plan,
        projects: organization.projects |> Enum.sort_by(& &1.updated_at, {:desc, Date}) |> Page.wrap(),
        members:
          organization.members
          |> Enum.sort_by(& &1.created_at, {:desc, Date})
          |> Enum.map(fn m -> m.user |> Azimutt.Repo.preload(:profile) end)
          |> Page.wrap(),
        invitations: organization.invitations |> Enum.sort_by(& &1.created_at, {:desc, Date}) |> Page.wrap(),
        activity:
          Dataset.chartjs_daily_data(
            [Admin.daily_organization_activity(organization) |> Dataset.from_values("Daily events")],
            start_stats,
            now
          ),
        events: Admin.get_organization_events(organization, events_page)
      )
    end
  end

  def refresh(conn, %{"organization_id" => organization_id} = params) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Admin.get_organization(organization_id) do
      Organizations.validate_organization_plan(organization)
      conn |> put_flash(:info, "Plan refreshed!") |> redirect(to: Routes.admin_organization_path(conn, :show, organization_id))
    end
  end
end
