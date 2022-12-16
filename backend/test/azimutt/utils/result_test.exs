defmodule Azimutt.Utils.ResultTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Result

  describe "result" do
    test "ok" do
      assert {:ok, 1} = Result.ok(1)
    end

    test "error" do
      assert {:error, "oops"} = Result.error("oops")
    end

    test "from_nillable" do
      assert {:ok, 1} = 1 |> Result.from_nillable()
      assert {:error, :not_found} = nil |> Result.from_nillable()
    end

    test "or_else" do
      assert 1 = {:ok, 1} |> Result.or_else(2)
      assert 2 = {:error, "oops"} |> Result.or_else(2)
    end

    test "map" do
      assert {:ok, 2} = {:ok, 1} |> Result.map(fn x -> x + 1 end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.map(fn x -> x + 1 end)
    end

    test "flat_map" do
      assert {:ok, {:ok, 2}} = {:ok, 1} |> Result.map(fn x -> {:ok, x + 1} end)
      assert {:ok, 2} = {:ok, 1} |> Result.flat_map(fn x -> {:ok, x + 1} end)
      assert {:error, "nooo"} = {:ok, 1} |> Result.flat_map(fn _x -> {:error, "nooo"} end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.flat_map(fn x -> x + 1 end)
    end

    test "map_error" do
      assert {:ok, 1} = {:ok, 1} |> Result.map_error(fn e -> e <> "ss" end)
      assert {:error, "oopsss"} = {:error, "oops"} |> Result.map_error(fn e -> e <> "ss" end)
      assert {:error, "err"} = :error |> Result.map_error(fn _ -> "err" end)
    end

    test "flat_map_error" do
      on_err = fn e -> {:error, e <> "ss"} end
      assert {:error, {:ok, 2}} = {:error, "oops"} |> Result.map_error(fn _e -> {:ok, 2} end)
      assert {:ok, 1} = {:ok, 1} |> Result.flat_map_error(fn _e -> {:ok, 2} end)
      assert {:ok, 2} = {:error, "oops"} |> Result.flat_map_error(fn _e -> {:ok, 2} end)
      assert {:error, "oopsss"} = {:error, "oops"} |> Result.flat_map_error(on_err)
      assert {:error, "err"} = :error |> Result.flat_map_error(fn _ -> {:error, "err"} end)
    end

    test "map_both" do
      on_ok = fn x -> x + 1 end
      on_err = fn e -> e <> "ss" end
      assert {:ok, 2} = {:ok, 1} |> Result.map_both(on_err, on_ok)
      assert {:error, "oopsss"} = {:error, "oops"} |> Result.map_both(on_err, on_ok)
      assert {:error, "err"} = :error |> Result.map_both(fn _ -> "err" end, on_ok)
    end

    test "map_with" do
      assert {:ok, {1, 2}} = {:ok, 1} |> Result.map_with(fn x -> x + 1 end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.map_with(fn x -> x + 1 end)
    end

    test "flat_map_with" do
      assert {:ok, {1, 2}} = {:ok, 1} |> Result.flat_map_with(fn x -> {:ok, x + 1} end)
      assert {:error, "nooo"} = {:ok, 1} |> Result.flat_map(fn _x -> {:error, "nooo"} end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.flat_map(fn x -> x + 1 end)
    end

    test "tap" do
      assert {:ok, 1} = {:ok, 1} |> Result.tap(fn x -> x + 1 end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.tap(fn x -> x + 1 end)
    end

    test "flat_tap" do
      assert {:ok, 1} = {:ok, 1} |> Result.flat_tap(fn x -> {:ok, x + 1} end)
      assert {:error, "nooo"} = {:ok, 1} |> Result.flat_tap(fn _x -> {:error, "nooo"} end)
    end

    test "tap_error" do
      assert {:ok, 1} = {:ok, 1} |> Result.tap_error(fn e -> e <> "ss" end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.tap_error(fn e -> e <> "ss" end)
      assert :error = :error |> Result.tap_error(fn _ -> "err" end)
    end

    test "tap_both" do
      on_ok = fn x -> x + 1 end
      on_err = fn e -> e <> "ss" end
      assert {:ok, 1} = {:ok, 1} |> Result.tap_both(on_err, on_ok)
      assert {:error, "oops"} = {:error, "oops"} |> Result.tap_both(on_err, on_ok)
      assert :error = :error |> Result.tap_both(fn _ -> "err" end, on_ok)
    end

    test "filter" do
      assert {:ok, 1} = {:ok, 1} |> Result.filter(fn x -> x == 1 end)
      assert {:error, :invalid_predicate} = {:ok, 1} |> Result.filter(fn x -> x > 1 end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.filter(fn x -> x > 1 end)
      assert {:error, :bad} = {:ok, 1} |> Result.filter(fn x -> x > 1 end, :bad)
    end

    test "filter_not" do
      assert {:error, :invalid_predicate} = {:ok, 1} |> Result.filter_not(fn x -> x == 1 end)
      assert {:ok, 1} = {:ok, 1} |> Result.filter_not(fn x -> x > 1 end)
      assert {:error, "oops"} = {:error, "oops"} |> Result.filter_not(fn x -> x > 1 end)
      assert {:error, :bad} = {:ok, 1} |> Result.filter_not(fn x -> x == 1 end, :bad)
    end

    test "sequence" do
      assert {:ok, [1, 2, 3]} = [{:ok, 1}, {:ok, 2}, {:ok, 3}] |> Result.sequence()
      assert {:error, "e1"} = [{:ok, 1}, {:error, "e1"}, {:error, "e2"}] |> Result.sequence()
    end
  end
end
