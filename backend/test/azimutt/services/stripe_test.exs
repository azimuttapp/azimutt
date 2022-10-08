defmodule Azimutt.Services.StripeTest do
  use Azimutt.DataCase
  alias Azimutt.Services.Stripe

  describe "Stripe" do
    @tag :skip
    test "create customer" do
      {:ok, id} = Stripe.init_customer()
      {:ok, _} = Stripe.update_organization(id, "orga_id", "Azimutt", "hey@azimutt.app", nil, false, "Loïc", "loic@mail.com")
      {:ok, _} = Stripe.delete_customer(id)
    end
  end
end
