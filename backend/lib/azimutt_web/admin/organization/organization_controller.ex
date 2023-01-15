defmodule AzimuttWeb.Admin.OrganizationController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
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
        events: Admin.get_organization_events(organization.id, conn |> Page.from_conn(%{prefix: "events", sort: "-created_at", size: 40}))
      )
    end
  end
end
