defmodule Azimutt.Services.StripeSrvTest do
  use Azimutt.DataCase
  alias Azimutt.Services.StripeSrv

  # run this using: `mix test test/azimutt/services/stripe_srv_test.exs`, you will need to have env var loaded
  describe "StripeSrv" do
    @tag :skip
    test "create_customer" do
      {:ok, customer} = StripeSrv.create_customer("orga_id", "Azimutt", "hello@azimutt.app", nil, false, "Loïc", "loic@mail.com")
      {:ok, _} = StripeSrv.update_customer(customer, "orga_id", "Azimutt 2", "hello2@azimutt.app", nil, false, "Loïc", "loic@mail.com")
      {:ok, _} = StripeSrv.delete_customer(customer)
    end

    @tag :skip
    test "get_subscriptions" do
      # subscriptions = StripeSrv.get_subscriptions("cus_QLWuSJQsP5COgx")
      # IO.inspect(subscriptions, label: "subscriptions")
    end

    @tag :skip
    test "get_price / get_plan" do
      assert StripeSrv.get_plan("", StripeSrv.get_price("solo", "monthly")) == {"solo", "monthly"}
      assert StripeSrv.get_plan("", StripeSrv.get_price("solo", "yearly")) == {"solo", "yearly"}
      assert StripeSrv.get_plan("", StripeSrv.get_price("team", "monthly")) == {"team", "monthly"}
      assert StripeSrv.get_plan("", StripeSrv.get_price("team", "yearly")) == {"team", "yearly"}
      assert StripeSrv.get_plan("", StripeSrv.get_price("pro", "monthly")) == {"pro", "monthly"}
      # assert StripeSrv.get_plan("prod_aaaa", "") == {"enterprise", "yearly"}
    end
  end
end
