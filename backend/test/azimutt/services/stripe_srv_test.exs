defmodule Azimutt.Services.StripeSrvTest do
  use Azimutt.DataCase
  alias Azimutt.Services.StripeSrv

  describe "StripeSrv" do
    @tag :skip
    test "create customer" do
      {:ok, customer} = StripeSrv.create_customer("orga_id", "Azimutt", "contact@azimutt.app", nil, false, "Loïc", "loic@mail.com")
      {:ok, _} = StripeSrv.update_customer(customer, "orga_id", "Azimutt 2", "contact2@azimutt.app", nil, false, "Loïc", "loic@mail.com")
      {:ok, _} = StripeSrv.delete_customer(customer)
    end
  end
end
