defmodule AzimuttWeb.OrganizationBillingController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization

  def index(conn, %{"organization_id" => id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(id, current_user) do
      if organization.stripe_subscription_id do
        status = Organizations.get_subscription_status(organization.stripe_subscription_id)

        case status do
          :active -> generate_billing_view(conn, "billing.html", organization, "Your subscription is active !")
          :past_due -> generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")
          :unpaid -> generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")
          :canceled -> generate_billing_view(conn, "subscribe.html", organization, "Your subscription is canceled")
          :incomplete -> generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")
          :incomplete_expired -> generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")
          :trialing -> generate_billing_view(conn, "billing.html", organization, "You are in free trial")
        end
      else
        generate_billing_view(conn, "subscribe.html", organization, "You haven't got subscribe yet !")
      end
    end
  end

  defp generate_billing_view(conn, file, organization, message) do
    conn
    |> put_view(AzimuttWeb.OrganizationView)
    |> render(file, organization: organization, active_plan: :free, message: message)
  end
end
