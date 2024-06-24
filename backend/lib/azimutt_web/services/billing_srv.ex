defmodule AzimuttWeb.Services.BillingSrv do
  @moduledoc false
  use AzimuttWeb, :controller
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Services.StripeSrv
  alias Azimutt.Tracking
  alias Azimutt.Utils.Result

  def subscribe(conn, %User{} = user, organization_id, plan, freq, success_url, cancel_url, error_path) do
    {:ok, %Organization{} = organization} = Organizations.get_organization(organization_id, user)
    price = StripeSrv.get_price(plan, freq)
    quantity = get_organization_seats(organization)
    Tracking.subscribe_init(user, organization, plan, freq, price, quantity)

    result =
      if organization.stripe_customer_id == nil do
        Organizations.create_stripe_customer(organization, user)
      else
        {:ok, organization}
      end
      |> Result.flat_map(fn orga_with_stripe ->
        StripeSrv.create_session(%{
          customer: orga_with_stripe.stripe_customer_id,
          success_url: success_url,
          cancel_url: cancel_url,
          # Get price_id from your Stripe dashboard for your product
          price_id: price,
          quantity: quantity,
          free_trial: if(orga_with_stripe.free_trial_used == nil, do: 14, else: nil)
        })
      end)

    case result do
      {:ok, session} ->
        Logger.info("Stripe session is create with success")
        Tracking.subscribe_start(user, organization, plan, freq, price, quantity)
        redirect(conn, external: session.url)

      {:error, %Stripe.Error{} = stripe_error} ->
        Logger.error("Cannot create Stripe Session for organization #{organization.id}: #{stripe_error.message}")
        Tracking.subscribe_error(user, organization, plan, freq, price, quantity, stripe_error)

        conn
        |> put_flash(
          :error,
          "Sorry something went wrong (#{stripe_error.message}), please contact us at #{Azimutt.config(:support_email)}."
        )
        |> redirect(to: error_path)
    end
  end

  defp get_organization_seats(%Organization{} = organization) do
    organization.members |> length
  end
end
