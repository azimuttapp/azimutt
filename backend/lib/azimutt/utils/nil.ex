defmodule Azimutt.Utils.Nil do
  @moduledoc "Helper functions on nil."

  @doc """
  A safe operator for `nil`: apply the `f` function to the value only if it's not `nil`.
  ## Examples
      iex> 1 |> Nil.safe(fn x -> x + 1 end)
      2
      iex> nil |> Nil.safe(fn x -> x + 1 end)
      nil
  """
  def safe(value, transform), do: if(value == nil, do: nil, else: transform.(value))
end
