defmodule Azimutt.Utils.IntxTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Intx

  describe "intx" do
    test "parse" do
      assert {:ok, 12} = "12" |> Intx.parse()
      assert {:error, "\"12a\" is not an Integer"} = "12a" |> Intx.parse()
    end
  end
end
