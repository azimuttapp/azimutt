defmodule Azimutt.StripeHandler do
  @moduledoc false
  @behaviour Stripe.WebhookHandler
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Tracking
  alias Azimutt.Tracking.Event
  # credo:disable-for-this-file

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.created"} = event) do
    subscription = event.data.object

    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(subscription.customer),
         {:ok, %Event{} = last_billing} <- Tracking.last_billing_loaded(organization) do
      Tracking.stripe_subscription_created(event, organization, last_billing.created_by, subscription.quantity, subscription.id)
      Organizations.update_organization_subscription(organization, subscription.id)
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.updated"} = event) do
    subscription = event.data.object
    previous = event.data.previous_attributes

    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(subscription.customer),
         {:ok, %Event{} = last_billing} <- Tracking.last_billing_loaded(organization) do
      cond do
        previous[:cancel_at] == nil && subscription.cancel_at != nil ->
          Tracking.stripe_subscription_canceled(event, organization, last_billing.created_by, subscription.quantity)

        previous[:cancel_at] != nil && subscription.cancel_at == nil ->
          Tracking.stripe_subscription_renewed(event, organization, last_billing.created_by, subscription.quantity)

        previous[:quantity] ->
          Tracking.stripe_subscription_quantity_updated(
            event,
            organization,
            last_billing.created_by,
            subscription.quantity,
            previous.quantity
          )

        previous[:status] == "incomplete" && subscription.status == "active" ->
          if organization.stripe_subscription_id == nil do
            # not saved in 'customer.subscription.created', don't know why :/
            Tracking.stripe_subscription_created(event, organization, last_billing.created_by, subscription.quantity, subscription.id)
            Organizations.update_organization_subscription(organization, subscription.id)
          else
            Tracking.stripe_unhandled_event(event)
          end

          :ok

        true ->
          Tracking.stripe_subscription_updated(event, organization, last_billing.created_by, subscription.quantity)
      end
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "billing_portal.session.created"} = event) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(event.data.object.customer),
         {:ok, %Event{} = last_billing} <- Tracking.last_billing_loaded(organization),
         do: Tracking.stripe_open_billing_portal(event, organization, last_billing.created_by)

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.paid"} = event) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(event.data.object.customer),
         {:ok, %Event{} = last_billing} <- Tracking.last_billing_loaded(organization),
         do: Tracking.stripe_invoice_paid(event, organization, last_billing.created_by)

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.payment_failed"} = event) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(event.data.object.customer),
         {:ok, %Event{} = last_billing} <- Tracking.last_billing_loaded(organization),
         do: Tracking.stripe_invoice_payment_failed(event, organization, last_billing.created_by)

    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(%Stripe.Event{} = event) do
    # IO.inspect(event, label: "Got Stripe event")
    Tracking.stripe_unhandled_event(event)
    :ok
  end

  # When create an orga: "customer.created", "customer.updated"
  # When subscribe for the first time: "charge.succeeded", "payment_method.attached", "customer.updated", "checkout.session.completed", "invoice.created", "invoice.finalized", "customer.subscription.created", "customer.subscription.updated", "invoice.updated", "invoice.paid", "invoice.payment_succeeded", "payment_intent.succeeded", "payment_intent.created"
  # When go to billing portal: "billing_portal.session.created"
  # When cancel subscription: "customer.subscription.updated"
  # When re-subscribe: "customer.subscription.updated"
  # When user join orga: "customer.subscription.updated", "invoiceitem.created", "invoiceitem.created"
end
