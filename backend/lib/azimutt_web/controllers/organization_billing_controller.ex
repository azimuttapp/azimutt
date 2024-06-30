defmodule AzimuttWeb.OrganizationBillingController do
  use AzimuttWeb, :controller
  require Logger
  alias Azimutt.Accounts
  alias Azimutt.Accounts.User
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
        organization.stripe_customer_id && StripeSrv.stripe_configured?() -> conn |> stripe_subscription_view(organization, current_user)
        true -> conn |> put_flash(:error, "Billing not available.") |> redirect(to: Routes.organization_path(conn, :show, organization))
      end
    end
  end

  defp stripe_subscription_view(conn, %Organization{} = organization, %User{} = current_user) do
    with {:ok, plan} <- Organizations.get_organization_plan(organization, current_user),
         {:ok, subscriptions} <- Organizations.get_subscriptions(organization) do
      {file, message} =
        cond do
          Enum.empty?(subscriptions) -> {"subscribe.html", "You haven't got subscribe yet !"}
          hd(subscriptions).status == "canceled" -> {"subscribe.html", "Your subscription has been canceled."}
          hd(subscriptions).status == "trialing" -> {"billing.html", "You are in free trial."}
          hd(subscriptions).status == "active" -> {"billing.html", "Your subscription is active !"}
          hd(subscriptions).status == "past_due" -> {"billing.html", "We have an issue with your subscription."}
          hd(subscriptions).status == "unpaid" -> {"billing.html", "We have an issue with your subscription."}
          hd(subscriptions).status == "incomplete" -> {"billing.html", "We have an issue with your subscription."}
          hd(subscriptions).status == "incomplete_expired" -> {"billing.html", "We have an issue with your subscription."}
          true -> {"billing.html", "Subscription is #{hd(subscriptions).status}, have a look at it."}
        end

      conn
      |> put_view(AzimuttWeb.OrganizationView)
      |> render(file, organization: organization, plan: plan, subscriptions: subscriptions, message: message)
    end
  end

  def refresh(conn, %{"organization_organization_id" => organization_id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user) do
      Organizations.validate_organization_plan(organization)

      conn
      |> put_flash(:info, "Plan refreshed!")
      |> redirect(to: Routes.organization_billing_path(conn, :index, organization_id, source: "refresh"))
    end
  end

  def new(conn, %{"organization_organization_id" => organization_id} = params) do
    current_user = conn.assigns.current_user

    conn
    |> BillingSrv.subscribe(
      current_user,
      organization_id,
      params["plan"],
      params["freq"],
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
    |> put_flash(:info, "Did you changed your mind? Let us know if you need clarifications: #{Azimutt.config(:contact_email)}")
    |> redirect(to: Routes.organization_billing_path(conn, :index, organization, source: "billing-cancel"))
  end
end
