defmodule Azimutt.Services.StripeSrv do
  @moduledoc false
  alias Azimutt.Utils.Result
  require Logger

  def create_customer(organization_id, name, email, description, is_personal, creator_name, creator_email) do
    if stripe_configured?() do
      # https://stripe.com/docs/api/customers/create
      Stripe.Customer.create(%{
        name: name,
        email: email,
        description: description,
        metadata: %{
          organization_id: organization_id,
          is_personal: is_personal,
          created_by: creator_name,
          created_by_email: creator_email
        }
      })
    else
      {:error, "Stripe not configured"}
    end
  end

  def update_customer(
        %Stripe.Customer{} = customer,
        organization_id,
        name,
        email,
        description,
        is_personal,
        creator_name,
        creator_email
      ) do
    if stripe_configured?() do
      # https://stripe.com/docs/api/customers/update
      Stripe.Customer.update(customer.id, %{
        name: name,
        email: email,
        description: description,
        metadata: %{
          organization_id: organization_id,
          is_personal: is_personal,
          created_by: creator_name,
          created_by_email: creator_email
        }
      })
    else
      {:error, "Stripe not configured"}
    end
  end

  def delete_customer(%Stripe.Customer{} = customer) do
    if stripe_configured?() do
      # https://stripe.com/docs/api/customers/delete
      Stripe.Customer.delete(customer.id)
    else
      {:error, "Stripe not configured"}
    end
  end

  def update_quantity(subscription_id, quantity) when is_bitstring(subscription_id) do
    if stripe_configured?() do
      Stripe.Subscription.update(subscription_id, %{quantity: quantity})
      |> Result.map_error(fn error -> error.message end)
      |> Result.tap_error(&Logger.error/1)
    else
      {:error, "Stripe not configured"}
    end
  end

  def get_subscription(subscription_id) when is_bitstring(subscription_id) do
    if stripe_configured?() do
      # FIXME: add cache to limit Stripe reads: https://github.com/sasa1977/con_cache
      # https://medium.com/@toddresudek/caching-in-an-elixir-phoenix-app-a499cdf91046
      case Stripe.Subscription.retrieve(subscription_id) do
        {:ok, %Stripe.Subscription{} = subscription} ->
          {:ok, subscription}

        {:error, %Stripe.Error{} = error} ->
          Logger.error(error.message)
          {:error, error.message}
      end
    else
      {:error, "Stripe not configured"}
    end
  end

  def create_session(%{customer: customer, success_url: success_url, cancel_url: cancel_url, price_id: price_id, quantity: quantity}) do
    if stripe_configured?() do
      Stripe.Session.create(%{
        mode: "subscription",
        customer: customer,
        line_items: [
          %{
            price: price_id,
            quantity: quantity
          }
        ],
        allow_promotion_codes: true,
        success_url: success_url,
        cancel_url: cancel_url
      })
    else
      {:error, "Stripe not configured"}
    end
  end

  def update_session(%{customer: customer, return_url: return_url}) do
    if stripe_configured?() do
      Stripe.BillingPortal.Session.create(%{
        customer: customer,
        return_url: return_url
      })
    else
      {:error, "Stripe not configured"}
    end
  end

  def subscription_url(stripe_sub_id) do
    "https://dashboard.stripe.com/subscriptions/#{stripe_sub_id}"
  end

  def stripe_configured?, do: !!Application.get_env(:stripity_stripe, :api_key)
end
