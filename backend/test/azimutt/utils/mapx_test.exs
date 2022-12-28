defmodule Azimutt.Utils.MapxTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Mapx

  describe "mapx" do
    test "fetch" do
      assert {:ok, "bar"} = %{foo: "bar"} |> Mapx.fetch(:foo)
      assert {:error, "Key :bar not found"} = %{foo: "bar"} |> Mapx.fetch(:bar)
    end

    test "map" do
      assert %{foo: 3, bob: 5} = %{foo: "bar", bob: "alice"} |> Mapx.map(fn {k, v} -> {k, String.length(v)} end)
    end

    test "map_values" do
      assert %{foo: 3, bob: 5} = %{foo: "bar", bob: "alice"} |> Mapx.map_values(&String.length/1)
    end

    test "atomize" do
      assert %{foo: "bar", bob: "alice"} = %{"foo" => "bar", "bob" => "alice"} |> Mapx.atomize()
    end
  end
end
