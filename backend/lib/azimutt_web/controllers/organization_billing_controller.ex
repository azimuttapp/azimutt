defmodule AzimuttWeb.OrganizationBillingController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Services.StripeSrv
  alias Azimutt.Utils.Uuid
  alias AzimuttWeb.Router.Helpers, as: Routes
  require Logger
  action_fallback AzimuttWeb.FallbackController

  def index(conn, %{"organization_id" => organization_id}) do
    current_user = conn.assigns.current_user

    if organization_id == Uuid.zero() do
      organization = Azimutt.Accounts.get_user_personal_organization(current_user)
      conn |> redirect(to: Routes.organization_billing_path(conn, :index, organization))
    end

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user) do
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
    with {:ok, plan} <- Organizations.get_organization_plan(organization) do
      conn
      |> put_view(AzimuttWeb.OrganizationView)
      |> render(file, organization: organization, plan: plan, message: message)
    end
  end

  def new(conn, %{"organization_id" => organization_id}) do
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(organization_id, current_user)

    case StripeSrv.create_session(%{
           customer: organization.stripe_customer_id,
           success_url: Routes.organization_billing_url(conn, :success, organization_id),
           cancel_url: Routes.organization_billing_url(conn, :cancel, organization_id),
           # Get price_id from your Stripe dashboard for your product
           price_id: Azimutt.config(:team_plan_price_id),
           quantity: get_organization_seats(organization)
         }) do
      {:ok, session} ->
        Logger.info("Stripe session is create with success")
        redirect(conn, external: session.url)

      {:error, stripe_error} ->
        Logger.error("Cannot create Stripe Session: #{stripe_error}")

        conn
        |> put_flash(:error, "Sorry something went wrong.")
        |> redirect(to: Routes.organization_billing_path(conn, :index, organization_id))
    end
  end

  defp get_organization_seats(organization) do
    organization.members |> length
  end

  def edit(conn, %{"organization_id" => organization_id}) do
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(organization_id, current_user)

    case StripeSrv.update_session(%{
           customer: organization.stripe_customer_id,
           return_url: Routes.website_url(conn, :index)
         }) do
      {:ok, session} ->
        Logger.info("Stripe Billing Portal session is create with success")
        redirect(conn, external: session.url)

      {:error, stripe_error} ->
        Logger.error("Cannot create Stripe  Billing Portal Session", stripe_error)

        conn
        |> put_flash(:error, "Sorry something went wrong.")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end

  def success(conn, %{"organization_id" => organization_id}) do
    conn
    |> put_flash(:info, "Thanks for subscribing!")
    |> redirect(to: Routes.organization_billing_path(conn, :index, organization_id))
  end

  def cancel(conn, %{"organization_id" => organization_id}) do
    conn
    |> put_flash(:info, "Sorry you didn't like our stuff.")
    |> redirect(to: Routes.organization_billing_path(conn, :index, organization_id))
  end
end
