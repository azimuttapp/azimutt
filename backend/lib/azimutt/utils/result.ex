# inspiration: https://hexdocs.pm/brex_result/readme.html
defmodule Azimutt.Utils.Result do
  @moduledoc "Helper functions on Results ({:ok, res} or {:error, err}) to handle them safely."

  # type for a Result
  @type t(e, x) :: {:ok, x} | {:error, e}
  # Result with String error
  @type s(x) :: t(String.t(), x)
  # Result with any as error
  @type a(x) :: t(any(), x)

  @doc """
  Creates a :ok Result.
  ## Examples
      iex> Result.ok(1)
      {:ok, 1}
  """
  def ok(value), do: {:ok, value}

  @doc """
  Creates an :error Result.
  ## Examples
      iex> Result.ok("booo")
      {:error, "booo"}
  """
  def error(err), do: {:error, err}

  @doc """
  Transforms nullable value into a Result, useful when using `Repo.one()`.
  ## Examples
      iex> nil |> Result.from_nillable
      {:error, :not_found}
      iex> 1 |> Result.from_nillable
      {:ok, 1}
  """
  def from_nillable(nil), do: {:error, :not_found}
  def from_nillable(val), do: {:ok, val}

  @doc """
  Get the value from a Result when :ok, or the default otherwise.
  ## Examples
      iex> {:ok, 1} |> Result.or_else(2)
      1
      iex> {:error, 1} |> Result.or_else(2)
      2
  """
  def or_else({:ok, val}, _default), do: val
  def or_else({:error, _err}, default), do: default

  @doc """
  Transforms the Result value (when :ok).
  ## Examples
      iex> {:ok, 1} |> Result.map(fn x -> x + 1 end)
      {:ok, 2}
      iex> {:error, 1} |> Result.map(fn x -> x + 1 end)
      {:error, 1}
  """
  def map({:ok, val}, f), do: ok(f.(val))
  def map({:error, _err} = res, _f), do: res

  @doc """
  Same as `map` but avoid stacking contexts.
  ## Examples
      iex> {:ok, 1} |> Result.map(fn x -> x + 1 end)
      {:ok, 2}
      iex> {:ok, 1} |> Result.map(fn x -> {:ok, x + 1} end)
      {:ok, {:ok, 2}}
      iex> {:ok, 1} |> Result.flat_map(fn x -> {:ok, x + 1} end)
      {:ok, 2}
      iex> {:ok, 1} |> Result.flat_map(fn x -> {:error, "oops"} end)
      {:error, "oops"}
      iex> {:error, "oops"} |> Result.flat_map(fn x -> {:ok, x + 1} end)
      {:error, "oops"}
      iex> {:error, "oops"} |> Result.flat_map(fn x -> {:error, "oops2"} end)
      {:error, "oops"}
  """
  def flat_map({:ok, val}, f), do: f.(val)
  def flat_map({:error, _err} = res, _f), do: res

  @doc """
  Transforms the Result error (when :error).
  ## Examples
      iex> {:ok, 1} |> Result.map_error(fn x -> x + 1 end)
      {:ok, 1}
      iex> {:error, 1} |> Result.map_error(fn x -> x + 1 end)
      {:error, 2}
      iex> :error |> Result.map_error(fn _ -> 1 end)
      {:error, 1}
  """
  def map_error({:ok, _val} = res, _f), do: res
  def map_error({:error, err}, f), do: error(f.(err))
  def map_error(:error, f), do: error(f.(nil))

  @doc """
  Same as `map_error` but avoid stacking contexts.
  ## Examples
      iex> {:error, "a"} |> Result.map_error(fn x -> x <> "b" end)
      {:error, "ab"}
      iex> {:error, "a"} |> Result.map_error(fn x -> {:error, x <> "b"} end)
      {:error, {:error, "ab"}}
      iex> {:error, "a"} |> Result.flat_map_error(fn x -> {:error, x <> "b"} end)
      {:error, "ab"}
      iex> {:error, "a"} |> Result.flat_map_error(fn x -> {:ok, x <> "b"} end)
      {:ok, "ab"}
      iex> {:ok, "a"} |> Result.flat_map_error(fn x -> {:error, x <> "b"} end)
      {:ok, "a"}
      iex> {:ok, "a"} |> Result.flat_map_error(fn x -> {:ok, x <> "b"} end)
      {:ok, "a"}
  """
  def flat_map_error({:ok, _val} = res, _f), do: res
  def flat_map_error({:error, err}, f), do: f.(err)
  def flat_map_error(:error, f), do: f.(nil)

  @doc """
  Transforms the Result content with the first function when :error or the second when :ok.
  ## Examples
      iex> {:ok, 1} |> Result.map_both(fn x -> x + 1 end, fn x -> x + 10 end)
      {:ok, 2}
      iex> {:error, 1} |> Result.map_both(fn x -> x + 1 end, fn x -> x + 10 end)
      {:error, 11}
  """
  def map_both({:ok, val}, _f_error, f_ok), do: ok(f_ok.(val))
  def map_both({:error, err}, f_error, _f_ok), do: error(f_error.(err))
  def map_both(:error, f_error, _f_ok), do: error(f_error.(nil))

  @doc """
  Execute the function on :ok but does not change the result
  ## Examples
      iex> {:ok, 1} |> Result.tap(fn x -> x + 1 end)
      {:ok, 1}
      iex> {:error, 1} |> Result.tap(fn x -> x + 1 end)
      {:error, 1}
  """
  def tap({:ok, val} = res, f) do
    f.(val)
    res
  end

  def tap({:error, _err} = res, _f), do: res

  @doc """
  Execure the function on :error but does not change the result
  ## Examples
      iex> {:ok, 1} |> Result.tap_error(fn x -> x + 1 end)
      {:ok, 1}
      iex> {:error, 1} |> Result.tap_error(fn x -> x + 1 end)
      {:error, 1}
      iex> :error |> Result.tap_error(fn _ -> 1 end)
      :error
  """
  def tap_error({:ok, _val} = res, _f), do: res

  def tap_error({:error, err} = res, f) do
    f.(err)
    res
  end

  def tap_error(:error = res, f) do
    f.(nil)
    res
  end

  @doc """
  Execute a function depending on the result but do not alter the result
  ## Examples
      iex> {:ok, 1} |> Result.tap_both(fn x -> x + 1 end, fn x -> x + 10 end)
      {:ok, 1}
      iex> {:error, 1} |> Result.tap_both(fn x -> x + 1 end, fn x -> x + 10 end)
      {:error, 1}
  """
  def tap_both({:ok, val} = res, _f_error, f_ok) do
    f_ok.(val)
    res
  end

  def tap_both({:error, err} = res, f_error, _f_ok) do
    f_error.(err)
    res
  end

  def tap_both(:error = res, f_error, _f_ok) do
    f_error.(nil)
    res
  end

  @doc """
  Transforms a list of results into a result of list.
  If they are all :ok, it will be :ok, otherwise returns the first :error.
  ## Examples
      iex> [{:ok, 1}, {:ok, 2}] |> Result.sequence
      {:ok, [1, 2]}
      iex> [{:ok, 1}, {:error, "err"}] |> Result.sequence
      {:error, "err"}
  """
  def sequence(results), do: results |> Enum.reduce(ok([]), &aggregate/2)
  defp aggregate(item, acc), do: acc |> flat_map(fn a -> item |> map(fn i -> concat(a, i) end) end)
  defp concat(arr, item), do: arr |> Enum.concat([item])
end
