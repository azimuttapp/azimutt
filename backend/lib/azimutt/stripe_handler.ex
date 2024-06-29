defmodule Azimutt.StripeHandler do
  @moduledoc false
  @behaviour Stripe.WebhookHandler
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Tracking
  # credo:disable-for-this-file

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.created"} = event) do
    subscription = event.data.object

    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(subscription.customer) do
      Organizations.validate_organization_plan(organization)

      if subscription.status == "trialing" do
        organization |> Organizations.use_free_trial(DateTime.utc_now())
      end

      Tracking.stripe_subscription_created(event, organization, subscription.id, subscription.status, subscription.plan.id, subscription.plan.interval, subscription.quantity)
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.deleted"} = event) do
    subscription = event.data.object

    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(subscription.customer) do
      Organizations.validate_organization_plan(organization)
      Tracking.stripe_subscription_deleted(event, organization, subscription.id, subscription.status, subscription.plan.id, subscription.plan.interval, subscription.quantity)
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.updated"} = event) do
    subscription = event.data.object
    previous = event.data.previous_attributes

    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(subscription.customer) do
      Organizations.validate_organization_plan(organization)

      cond do
        previous[:cancel_at] == nil && subscription.cancel_at != nil ->
          Tracking.stripe_subscription_canceled(event, organization, subscription.quantity)

        previous[:cancel_at] != nil && subscription.cancel_at == nil ->
          Tracking.stripe_subscription_renewed(event, organization, subscription.quantity)

        previous[:quantity] ->
          Tracking.stripe_subscription_quantity_updated(event, organization, subscription.quantity, previous.quantity)

        true ->
          # TODO: fails when previous is Stripe.SubscriptionItem :/
          Tracking.stripe_subscription_updated(event, organization, previous)
      end
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "billing_portal.session.created"} = event) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(event.data.object.customer) do
      Tracking.stripe_open_billing_portal(event, organization)
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.paid"} = event) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(event.data.object.customer) do
      Tracking.stripe_invoice_paid(event, organization)
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.payment_failed"} = event) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization_by_customer(event.data.object.customer) do
      Tracking.stripe_invoice_payment_failed(event, organization)
    end

    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(%Stripe.Event{} = event) do
    # IO.inspect(event, label: "stripe_unhandled_event")
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
