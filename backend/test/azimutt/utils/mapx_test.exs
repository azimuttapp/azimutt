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

    test "filter" do
      assert %{bob: "alice"} = %{foo: "bar", bob: "alice"} |> Mapx.filter(fn {k, v} -> String.length(v) > 4 end)
    end

    test "map_keys" do
      assert %{"foo" => "bar", "bob" => "alice"} = %{foo: "bar", bob: "alice"} |> Mapx.map_keys(&Atom.to_string/1)
    end

    test "map_values" do
      assert %{foo: 3, bob: 5} = %{foo: "bar", bob: "alice"} |> Mapx.map_values(&String.length/1)
    end

    test "put_no_nil" do
      assert %{foo: "bar"} = %{foo: "bar", bob: "alice"} |> Mapx.put_no_nil(:bob, nil)
      assert %{foo: "bar", bob: "claude"} = %{foo: "bar", bob: "alice"} |> Mapx.put_no_nil(:bob, "claude")
    end

    test "put_in" do
      assert %{meta: %{events: %{columns: %{id: %{notes: "bbb"}}}}} =
               %{meta: %{events: %{columns: %{id: %{notes: "aaa"}}}}} |> Mapx.put_in([:meta, :events, :columns, :id, :notes], "bbb")

      assert %{meta: %{events: %{columns: %{id: %{notes: "ccc"}}}}} = %{meta: %{}} |> Mapx.put_in([:meta, :events, :columns, :id, :notes], "ccc")
    end

    test "update_in" do
      assert %{meta: %{events: %{notes: "bbb", columns: %{id: %{notes: "aaa"}}}}} =
               %{meta: %{events: %{columns: %{id: %{notes: "aaa"}}}}} |> Mapx.update_in([:meta, :events], fn v -> (v || %{}) |> Map.merge(%{notes: "bbb"}) end)

      assert %{meta: %{events: %{notes: "ccc"}}} = %{meta: %{}} |> Mapx.update_in([:meta, :events], fn v -> (v || %{}) |> Map.merge(%{notes: "ccc"}) end)
    end

    test "toggle" do
      assert %{foo: "bar"} = %{foo: "bar", bob: "alice"} |> Mapx.toggle(:bob, "alice")
      assert %{foo: "bar", bob: "loic"} = %{foo: "bar", bob: "alice"} |> Mapx.toggle(:bob, "loic")
      assert %{foo: "bar", bob: "alice", lol: "mdr"} = %{foo: "bar", bob: "alice"} |> Mapx.toggle(:lol, "mdr")
    end

    test "atomize" do
      assert %{foo: "bar", bob: "alice"} = %{"foo" => "bar", "bob" => "alice"} |> Mapx.atomize()
    end
  end
end
