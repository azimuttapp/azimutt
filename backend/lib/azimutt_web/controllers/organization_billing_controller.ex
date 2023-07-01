defmodule AzimuttWeb.OrganizationBillingController do
  use AzimuttWeb, :controller
  require Logger
  alias Azimutt.Accounts
  alias Azimutt.CleverCloud
  alias Azimutt.Heroku
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Services.StripeSrv
  alias Azimutt.Tracking
  alias Azimutt.Utils.Uuid
  alias AzimuttWeb.Router.Helpers, as: Routes
  alias AzimuttWeb.Services.BillingSrv
  action_fallback AzimuttWeb.FallbackController

  def index(conn, %{"organization_organization_id" => organization_id} = params) do
    source = params["source"]
    current_user = conn.assigns.current_user

    if organization_id == Uuid.zero() do
      organization = Accounts.get_user_default_organization(current_user)
      conn |> redirect(to: Routes.organization_billing_path(conn, :index, organization, source: source))
    end

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user) do
      Tracking.billing_loaded(current_user, organization, source)

      cond do
        organization.clever_cloud_resource -> conn |> redirect(external: CleverCloud.app_addons_url())
        organization.heroku_resource -> conn |> redirect(external: Heroku.app_addons_url(organization.heroku_resource.app))
        organization.stripe_subscription_id -> conn |> stripe_subscription_view(organization)
        true -> generate_billing_view(conn, "subscribe.html", organization, "You haven't got subscribe yet !")
      end
    end
  end

  defp stripe_subscription_view(conn, %Organization{} = organization) do
    case Organizations.get_subscription_status(organization.stripe_subscription_id) do
      {:ok, :active} ->
        generate_billing_view(conn, "billing.html", organization, "Your subscription is active !")

      {:ok, :past_due} ->
        generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")

      {:ok, :unpaid} ->
        generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")

      {:ok, :canceled} ->
        generate_billing_view(conn, "subscribe.html", organization, "Your subscription is canceled")

      {:ok, :incomplete} ->
        generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")

      {:ok, :incomplete_expired} ->
        generate_billing_view(conn, "billing.html", organization, "We have an issue with your subscription")

      {:ok, :trialing} ->
        generate_billing_view(conn, "billing.html", organization, "You are in free trial")

      {:error, err} ->
        conn |> put_flash(:error, "Can't show view: #{err}.") |> redirect(to: Routes.organization_path(conn, :show, organization))
    end
  end

  defp generate_billing_view(conn, file, organization, message) do
    with {:ok, plan} <- Organizations.get_organization_plan(organization) do
      conn
      |> put_view(AzimuttWeb.OrganizationView)
      |> render(file, organization: organization, plan: plan, message: message)
    end
  end

  def new(conn, %{"organization_organization_id" => organization_id}) do
    current_user = conn.assigns.current_user

    conn
    |> BillingSrv.subscribe_pro(
      current_user,
      organization_id,
      Routes.organization_billing_url(conn, :success, organization_id),
      Routes.organization_billing_url(conn, :cancel, organization_id),
      Routes.organization_billing_path(conn, :index, organization_id, source: "billing-error")
    )
  end

  def edit(conn, %{"organization_organization_id" => organization_id}) do
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(organization_id, current_user)

    if organization.stripe_customer_id != nil do
      case StripeSrv.update_session(%{
             customer: organization.stripe_customer_id,
             return_url: Routes.organization_billing_url(conn, :index, organization, source: "billing-portal")
           }) do
        {:ok, session} ->
          Logger.info("Stripe Billing Portal session is create with success")
          redirect(conn, external: session.url)

        {:error, stripe_error} ->
          Logger.error("Cannot create Stripe  Billing Portal Session", stripe_error)

          conn
          |> put_flash(:error, "Sorry something went wrong.")
          |> redirect(to: Routes.organization_path(conn, :show, organization))
      end
    else
      conn |> put_flash(:error, "Can't show view.") |> redirect(to: Routes.organization_path(conn, :show, organization))
    end
  end

  def success(conn, %{"organization_organization_id" => organization_id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         {:ok, subscribe_start} <- Tracking.last_subscribe_start(current_user) do
      Tracking.subscribe_success(current_user, organization, subscribe_start.details)

      conn
      |> put_flash(:info, "Thanks for subscribing!")
      |> redirect(to: Routes.organization_billing_path(conn, :index, organization, source: "billing-success"))
    end
  end

  def cancel(conn, %{"organization_organization_id" => organization_id}) do
    current_user = conn.assigns.current_user
    {:ok, %Organization{} = organization} = Organizations.get_organization(organization_id, current_user)
    Tracking.subscribe_abort(current_user, organization)

    conn
    |> put_flash(:info, "Sorry you didn't like our stuff.")
    |> redirect(to: Routes.organization_billing_path(conn, :index, organization, source: "billing-cancel"))
  end
end
