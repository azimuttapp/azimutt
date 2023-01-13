defmodule AzimuttWeb.Admin.OrganizationController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html", organizations: Admin.list_organizations(1000))
  end

  def show(conn, %{"id" => organization_id}) do
    with {:ok, organization} <- Admin.get_organization(organization_id) do
      conn |> render("show.html", organization: organization)
    end
  end
end
