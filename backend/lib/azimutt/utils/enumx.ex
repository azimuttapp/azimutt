defmodule Azimutt.Utils.Enumx do
  @moduledoc "Helper functions on Enum."

  @doc """
  Return a Result with the first value of the enum if size is one, otherwise an error
  ## Examples
      iex> [] |> Enumx.one
      {:error, :not_found}
      iex> [1] |> Enumx.one
      {:ok, 1}
      iex> [1, 2] |> Enumx.one
      {:error, :many_found}
  """
  def one(enumerable) do
    length = length(enumerable)

    cond do
      length == 0 -> {:error, :not_found}
      length == 1 -> {:ok, enumerable |> Enum.at(0)}
      true -> {:error, :many_found}
    end
  end

  @doc """
  Return enumerable grouped in fix sized groups, the last one may be smalled
  ## Examples
      iex> [1, 2, 3, 4, 5] |> Enumx.grouped(2)
      [[1, 2], [3, 4], [5]]
  """
  def grouped(enumerable, size) do
    {last, res} =
      enumerable
      |> Enum.reduce({[], []}, fn i, {acc, res} ->
        if acc |> length() < size do
          {acc |> Enum.concat([i]), res}
        else
          {[i], res |> Enum.concat([acc])}
        end
      end)

    res |> Enum.concat([last])
  end

  @doc """
  Return enumerable keeping a fixed window for each element, first windows will be smaller, use `|> Enum.drop(size)` to have all equal windows
  ## Examples
      iex> [1, 2, 3, 4, 5] |> Enumx.window(2)
      [[1], [1, 2], [2, 3], [3, 4], [4, 5]]
  """
  def window(enumerable, size) do
    enumerable
    |> Enum.scan([], fn i, acc ->
      r = acc |> Enum.concat([i])
      if(r |> length() > size, do: r |> Enum.drop(1), else: r)
    end)
  end
end
