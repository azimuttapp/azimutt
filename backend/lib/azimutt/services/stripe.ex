defmodule Azimutt.Services.Stripe do
  @moduledoc false
  alias Stripe, as: Stripity

  # https://stripe.com/docs/api/customers/create
  def init_customer, do: Stripity.Customer.create(%{})

  # https://stripe.com/docs/api/customers/delete
  def delete_customer(%Stripity.Customer{} = customer), do: Stripity.Customer.delete(customer.id)

  # https://stripe.com/docs/api/customers/update
  def update_organization(
        %Stripity.Customer{} = customer,
        organization_id,
        name,
        email,
        description,
        is_personal,
        creator_name,
        creator_email
      ) do
    Stripity.Customer.update(customer.id, %{
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
end
