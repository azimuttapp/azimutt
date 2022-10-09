defmodule AzimuttWeb.OrganizationBillingController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization

  def index(conn, %{"organization_id" => id}) do
    current_user = conn.assigns.current_user

<<<<<<< HEAD
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(id, current_user),
         do: conn |> put_view(AzimuttWeb.OrganizationView) |> render("billing.html", organization: organization, active_plan: :free)
=======
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(id, current_user) do
      with {:ok, current_subscription} <- Stripe.Subscription.retrieve("sub_1LqfILCaPXsf4vehL174ZNlf") do
        conn |> put_view(AzimuttWeb.OrganizationView) |> render("billing.html", organization: organization, active_plan: current_subscription.plan.active)
      end
    end

>>>>>>> 38542dd (update billing controller)
  end
end
