defmodule Azimutt.Utils.Stringx do
  @moduledoc "Helper functions on String."

  @doc """
  A smart stringification from any value
  """
  # def inspect(%Ecto.Changeset{valid?: false, errors: errors}), do: "Invalid changeset: #{errors |> Enum.map(fn e -> Stringx.inspect(e) end) |> Enum.join(", ")}"
  def inspect(value), do: Kernel.inspect(value)
end
