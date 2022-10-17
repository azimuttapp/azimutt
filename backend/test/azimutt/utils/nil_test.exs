defmodule Azimutt.Utils.NilTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Nil

  describe "nil" do
    test "safe" do
      assert 2 = 1 |> Nil.safe(fn x -> x + 1 end)
      assert nil == nil |> Nil.safe(fn x -> x + 1 end)
    end
  end
end
