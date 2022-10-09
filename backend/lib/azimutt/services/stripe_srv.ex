defmodule Azimutt.Services.StripeSrv do
  @moduledoc false
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

  def get_subscription(subscription_id) when is_bitstring(subscription_id) do
    case Stripe.Subscription.retrieve(subscription_id) do
      {:ok, %Stripe.Subscription{} = subscription} ->
        {:ok, subscription}

      {:error, %Stripe.Error{} = error} ->
        Logger.error(error.message)
        {:error, error.message}
    end
  end
end
