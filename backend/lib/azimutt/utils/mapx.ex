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
  Same as `map` but only on the values.
  It iterates over all the values and apply them the `f` function.
  ## Examples
      iex> %{foo: "bar", bob: "alice"} |> Mapx.map_values(&String.length/1)
      %{foo: 3, bob: 5}
  """
  def map_values(enumerable, f), do: enumerable |> Enum.map(fn {k, v} -> {k, f.(v)} end) |> Map.new()

  @doc """
  Transform Map keys to :atom
  ## Examples
      iex> %{"foo" => "bar", "bob" => "alice"} |> Mapx.atomize()
      %{foo: "bar", bob: "alice"}
  """
  def atomize(struct), do: struct |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
end
