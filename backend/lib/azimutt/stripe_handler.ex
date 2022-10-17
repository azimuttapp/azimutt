defmodule Azimutt.StripeHandler do
  @moduledoc false
  @behaviour Stripe.WebhookHandler
  alias Azimutt.Organizations
  # credo:disable-for-this-file

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.paid"} = event) do
    IO.inspect("Payment Success")
    IO.inspect(event)
    # Continue to provision the subscription as payments continue to be made.
    # Store the status in your database and check when a user accesses your service.
    # This approach helps you avoid hitting rate limits.
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.payment_failed"} = event) do
    IO.inspect("Payment Failed")
    IO.inspect(event)
    # The payment failed or the customer does not have a valid payment method.
    # The subscription becomes past_due. Notify your customer and send them to the
    # customer portal to update their payment information.
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = event) do
    IO.inspect("Checkout Session Completed")
    IO.inspect(event)
    # Payment is successful and the subscription is created.
    # You should provision the subscription and save the customer ID to your database.
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.created"} = event) do
    customer_id = event.data.object.customer
    subscription_id = event.data.object.id
    IO.inspect(customer_id)
    IO.inspect(subscription_id)
    IO.inspect(event)
    Organizations.update_organization_subscription(customer_id, subscription_id)
    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(_event), do: :ok
end
