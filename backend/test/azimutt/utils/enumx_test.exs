defmodule Azimutt.Utils.EnumxTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Enumx

  describe "enumx" do
    test "one" do
      assert {:error, :not_found} = [] |> Enumx.one()
      assert {:ok, 1} = [1] |> Enumx.one()
      assert {:error, :many_found} = [1, 2] |> Enumx.one()
    end

    test "grouped" do
      assert [[1, 2], [3, 4], [5]] = [1, 2, 3, 4, 5] |> Enumx.grouped(2)
    end

    test "window" do
      assert [[1], [1, 2], [2, 3], [3, 4], [4, 5]] = [1, 2, 3, 4, 5] |> Enumx.window(2)
    end
  end
end
