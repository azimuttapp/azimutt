defmodule Azimutt.Utils.Uuid do
  @moduledoc "Helper functions on UUIDs."

  @doc """
  Return a UUID string full of zeros
  ## Examples
      iex> Uuid.zero()
      "00000000-0000-0000-0000-000000000000"
  """
  def zero, do: "00000000-0000-0000-0000-000000000000"

  def is_valid?(value), do: Ecto.UUID.cast(value) != :error
end
