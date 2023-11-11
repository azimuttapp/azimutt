defmodule Azimutt.Utils.Mapx do
  @moduledoc "Helper functions on Map."
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  @doc """
  Same as `Map.fetch` but return a better error
  ## Examples
      iex> %{foo: "bar"} |> Mapx.fetch(:foo)
      {:ok, "bar"}
      iex> %{foo: "bar"} |> Mapx.fetch(:bar)
      {:error, "Missing :bar key"}
  """
  def fetch(enumerable, key), do: enumerable |> Map.fetch(key) |> Result.map_error(fn _ -> "Key #{Stringx.inspect(key)} not found" end)

  @doc """
  Same as `Enum.map` but for a Map.
  It iterates over all the key/value pairs and apply them the `f` function.
  ## Examples
      iex> %{foo: "bar", bob: "alice"} |> Mapx.map(fn {key, value} -> {key, String.length(value)} end)
      %{foo: 3, bob: 5}
  """
  def map(enumerable, f), do: enumerable |> Enum.map(f) |> Map.new()

  @doc """
  Same as `map` but only on the keys.
  It iterates over all the keys and apply them the `f` function.
  ## Examples
      iex> %{foo: "bar", bob: "alice"} |> Mapx.map_keys(fn k -> k <> "s" end)
      %{foos: "bar", bobs: "alice"}
  """
  def map_keys(enumerable, f), do: enumerable |> Enum.map(fn {k, v} -> {f.(k), v} end) |> Map.new()

  @doc """
  Same as `map` but only on the values.
  It iterates over all the values and apply them the `f` function.
  ## Examples
      iex> %{foo: "bar", bob: "alice"} |> Mapx.map_values(&String.length/1)
      %{foo: 3, bob: 5}
  """
  def map_values(enumerable, f), do: enumerable |> Enum.map(fn {k, v} -> {k, f.(v)} end) |> Map.new()

  @doc """
  Same as `put` but if value is `nil` it removes the key.
  ## Examples
      iex> %{foo: "bar", bob: "alice"} |> Mapx.put_no_nil(:bob, "claude")
      %{foo: "bar", bob: "claude"}
      iex> %{foo: "bar", bob: "alice"} |> Mapx.put_no_nil(:bob, nil)
      %{foo: "bar"}
  """
  def put_no_nil(enumerable, key, value) do
    if value == nil do
      enumerable |> Map.delete(key)
    else
      enumerable |> Map.put(key, value)
    end
  end

  @doc """
  Remove a key if it's present with the expected value, or set it
  ## Examples
      iex> %{foo: "bar", bob: "alice"} |> Mapx.toggle(:foo, "bar")
      %{bob: "alice"}
      iex> %{foo: "bar", bob: "alice"} |> Mapx.toggle(:foo, "test")
      %{foo: "test", bob: "alice"}
      iex> %{foo: "bar", bob: "alice"} |> Mapx.toggle(:lol, "mdr")
      %{foo: "bar", bob: "alice", lol: "mdr"}
  """
  def toggle(enumerable, key, value) do
    if enumerable |> Map.get(key) == value do
      enumerable |> Map.delete(key)
    else
      enumerable |> Map.put(key, value)
    end
  end

  @doc """
  Transform Map keys to :atom
  ## Examples
      iex> %{"foo" => "bar", "bob" => "alice"} |> Mapx.atomize()
      %{foo: "bar", bob: "alice"}
  """
  def atomize(struct), do: struct |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
end
