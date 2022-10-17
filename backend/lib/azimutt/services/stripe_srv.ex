defmodule Azimutt.Services.StripeSrv do
  @moduledoc false
  alias Azimutt.Utils.Result
  require Logger
  # https://stripe.com/docs/api/customers/create
  def init_customer(name), do: Stripe.Customer.create(%{name: name})

  # https://stripe.com/docs/api/customers/delete
  def delete_customer(%Stripe.Customer{} = customer), do: Stripe.Customer.delete(customer.id)

  # https://stripe.com/docs/api/customers/update
  def update_organization(
        %Stripe.Customer{} = customer,
        organization_id,
        name,
        email,
        description,
        is_personal,
        creator_name,
        creator_email
      ) do
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
  end

  def update_quantity(subscription_id, quantity) when is_bitstring(subscription_id) do
    Stripe.Subscription.update(subscription_id, %{quantity: quantity})
    |> Result.map_error(fn error -> error.message end)
    |> Result.tap_error(&Logger.error/1)
  end

  def get_subscription(subscription_id) when is_bitstring(subscription_id) do
    # FIXME: add cache to limit Stripe reads: https://github.com/sasa1977/con_cache
    # https://medium.com/@toddresudek/caching-in-an-elixir-phoenix-app-a499cdf91046
    case Stripe.Subscription.retrieve(subscription_id) do
      {:ok, %Stripe.Subscription{} = subscription} ->
        {:ok, subscription}

      {:error, %Stripe.Error{} = error} ->
        Logger.error(error.message)
        {:error, error.message}
    end
  end
end
