defmodule Azimutt.Services.StripeSrv do
  @moduledoc false
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

  def get_subscriptions(customer_id) when is_bitstring(customer_id) do
    if stripe_configured?() do
      Stripe.Subscription.list(%{customer: customer_id})
    else
      {:error, "Stripe not configured"}
    end
  end

  def create_session(%{customer: customer, success_url: success_url, cancel_url: cancel_url, price_id: price_id, quantity: quantity, free_trial: free_trial}) do
    # https://docs.stripe.com/api/checkout/sessions/create
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
        subscription_data:
          if(free_trial,
            do: %{
              trial_period_days: free_trial,
              trial_settings: %{
                end_behavior: %{
                  missing_payment_method: "cancel"
                }
              }
            },
            else: %{}
          ),
        automatic_tax: %{enabled: true},
        payment_method_collection: "if_required",
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

  def get_price(plan, freq) do
    case {plan, freq} do
      {"solo", "monthly"} -> Azimutt.config(:stripe_price_solo_monthly)
      {"solo", "yearly"} -> Azimutt.config(:stripe_price_solo_yearly)
      {"team", "monthly"} -> Azimutt.config(:stripe_price_team_monthly)
      {"team", "yearly"} -> Azimutt.config(:stripe_price_team_yearly)
      {"pro", "monthly"} -> Azimutt.config(:stripe_price_pro_monthly)
    end
  end

  def get_plan(product, price) do
    cond do
      price == Azimutt.config(:stripe_price_solo_monthly) -> {"solo", "monthly"}
      price == Azimutt.config(:stripe_price_solo_yearly) -> {"solo", "yearly"}
      price == Azimutt.config(:stripe_price_team_monthly) -> {"team", "monthly"}
      price == Azimutt.config(:stripe_price_team_yearly) -> {"team", "yearly"}
      price == Azimutt.config(:stripe_price_pro_monthly) -> {"pro", "monthly"}
      product == Azimutt.config(:stripe_product_enterprise) -> {"enterprise", "yearly"}
    end
  end

  def customer_url(customer_id) do
    "https://dashboard.stripe.com/customers/#{customer_id}"
  end

  def stripe_configured?, do: !!Application.get_env(:stripity_stripe, :api_key)
end
