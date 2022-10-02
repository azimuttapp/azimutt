defmodule AzimuttWeb.UserPlanController do
  @moduledoc """
    The stripe subscription controller
  """
  use AzimuttWeb, :controller
  alias AzimuttWeb.Router.Helpers, as: Routes
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

  defp get_customer_from_email(_email) do
    # Handle storing and retrieving customer_id
    # Is on the format
    # customer_id = "cus_MH7xcT1tSmxOo3"
    "cus_MH7xcT1tSmxOo3"
  end

  def new(conn, %{"email" => email}) do
    # Or if it is a recurring customer, you can provide customer_id
    customer_id = get_customer_from_email(email)
    # Get this from the Stripe dashboard for your product
    price_id = Azimutt.config(:team_plan_price_id)
    quantity = 1

    session_config = %{
      success_url: Routes.user_plan_url(conn, :success),
      cancel_url: Routes.user_plan_url(conn, :cancel),
      mode: "subscription",
      line_items: [
        %{
          price: price_id,
          quantity: quantity
        }
      ]
    }

    # Previous customer? customer_id else customer_email
    # The stripe API only allows one of {customer_email, customer}
    session_config =
      if customer_id,
        do: Map.put(session_config, :customer, customer_id),
        else: Map.put(session_config, :customer_email, email)

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

  def edit(conn, %{"email" => email}) do
    customer_id = get_customer_from_email(email)

    case Stripe.BillingPortal.Session.create(%{
           customer: customer_id,
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
