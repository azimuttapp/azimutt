defmodule Azimutt.Utils.Intx do
  @moduledoc "Helper functions on Integer."

  @doc """
  Safely parse a String into an Integer.
  ## Examples
      iex> "1" |> Intx.parse()
      {:ok, 1}
      iex> "ab" |> Intx.parse()
      {:error, "'ab' is not an Integer"}
  """
  def parse(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> {:error, "#{inspect(value)} is not an Integer"}
    end
  end

  def parse(value), do: {:error, "#{inspect(value)} is not an Integer"}
end
