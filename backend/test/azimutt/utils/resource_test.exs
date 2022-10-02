defmodule Azimutt.Utils.ResourceTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Resource

  describe "resource" do
    test "exec block after open" do
      assert {:ok, "Yay!"} =
               Resource.use(fn -> {:ok, "Yay"} end, fn _ -> nil end, fn handle ->
                 {:ok, handle <> "!"}
               end)
    end

    test "catch raised error in open" do
      assert {:error, %RuntimeError{message: "bad"}} = Resource.use(fn -> raise "bad" end, fn _ -> nil end, fn _ -> nil end)
    end

    test "catch raised error in close" do
      assert {:error, %RuntimeError{message: "bad"}} = Resource.use(fn -> {:ok, nil} end, fn _ -> raise "bad" end, fn _ -> nil end)
    end

    test "catch raised error in block" do
      assert {:error, %RuntimeError{message: "bad"}} = Resource.use(fn -> {:ok, nil} end, fn _ -> nil end, fn _ -> raise "bad" end)
    end

    test "catch bad open result" do
      assert {:error, %MatchError{term: nil}} = Resource.use(fn -> nil end, fn _ -> nil end, fn _ -> nil end)
    end
  end
end
