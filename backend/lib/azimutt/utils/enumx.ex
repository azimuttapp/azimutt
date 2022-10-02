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
end
