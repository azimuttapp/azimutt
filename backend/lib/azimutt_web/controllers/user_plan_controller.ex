defmodule AzimuttWeb.UserPlanController do
  @moduledoc """
    The stripe subscription controller
  """
  use AzimuttWeb, :controller
  alias AzimuttWeb.Router.Helpers, as: Routes
  alias Azimutt.Organizations
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def success(conn, _params) do
    conn
    |> put_flash(:info, "Thanks for subscribing!")
    |> redirect(to: Routes.user_dashboard_path(conn, :index))
  end

  def cancel(conn, _params) do
    conn
    |> put_flash(:info, "Sorry you didn't like Our Stuff.")
    |> redirect(to: Routes.user_dashboard_path(conn, :index))
  end

  defp get_seats_from_organization(organization) do
    organization.members |> length
  end

  def new(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(id, current_user)

    # Get this from the Stripe dashboard for your product
    price_id = Azimutt.config(:team_plan_price_id)
    quantity = get_seats_from_organization(organization)

    session_config = %{
      success_url: Routes.user_plan_url(conn, :success),
      cancel_url: Routes.user_plan_url(conn, :cancel),
      mode: "subscription",
      customer: organization.stripe_customer_id,
      line_items: [
        %{
          price: price_id,
          quantity: quantity
        }
      ]
    }

    case Stripe.Session.create(session_config) do
      {:ok, session} ->
        Logger.info("Stripe session is create with success")
        redirect(conn, external: session.url)

      {:error, stripe_error} ->
        Logger.error("Cannot create Stripe Session", stripe_error)

        conn
        |> put_flash(:error, "Sorry something went wrong.")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end

  def edit(conn, organization) do
    case Stripe.BillingPortal.Session.create(%{
           customer: organization.stripe_customer_id,
           return_url: Routes.page_url(conn, :index)
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
end
