defmodule Azimutt.Utils.ProcessTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Process

  describe "process" do
    test "return normal value" do
      assert {:ok, "Hello"} = Process.capture(1000, fn -> "Hello" end)
    end

    test "return success result" do
      assert {:ok, "Hello"} = Process.capture(1000, fn -> {:ok, "Hello"} end)
    end

    test "return failure result" do
      assert {:error, "bad"} = Process.capture(1000, fn -> {:error, "bad"} end)
    end

    test "catch raise" do
      assert {:error, {%RuntimeError{message: "bad"}, _}} = Process.capture(1000, fn -> raise "bad" end)
    end

    test "catch throw" do
      assert {:error, {{:nocatch, "bad"}, _}} = Process.capture(1000, fn -> throw("bad") end)
    end
  end
end
