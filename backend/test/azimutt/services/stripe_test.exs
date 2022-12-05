defmodule Azimutt.Services.StripeTest do
  use Azimutt.DataCase
  alias Azimutt.Services.StripeSrv

  describe "StripeSrv" do
    @tag :skip
    test "create customer" do
      {:ok, customer} = StripeSrv.init_customer("TMP - Azimutt", %{test: "Hello"})
      {:ok, _} = StripeSrv.update_customer(customer, "orga_id", "Azimutt", "hey@azimutt.app", nil, false, "Loïc", "loic@mail.com")
      {:ok, _} = StripeSrv.delete_customer(customer)
    end
  end
end
