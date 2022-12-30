defmodule AzimuttWeb.Admin.OrganizationController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def show(conn, %{"id" => organization_id}) do
    with {:ok, organization} <- Azimutt.Admin.get_organization(organization_id) do
      render(conn, "show.html", organization: organization)
    end
  end
end
