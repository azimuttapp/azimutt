defmodule Azimutt.Utils.EnumxTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Enumx

  describe "enumx" do
    test "one" do
      assert {:error, :not_found} = [] |> Enumx.one()
      assert {:ok, 1} = [1] |> Enumx.one()
      assert {:error, :many_found} = [1, 2] |> Enumx.one()
    end
  end
end
