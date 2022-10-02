defmodule AzimuttWeb.OrganizationBillingController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization

  def index(conn, %{"organization_id" => id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(id, current_user),
         do: conn |> put_view(AzimuttWeb.OrganizationView) |> render("billing.html", organization: organization)
  end
end
