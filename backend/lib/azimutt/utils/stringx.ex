defmodule Azimutt.Utils.Stringx do
  @moduledoc "Helper functions on String."

  def pluralize(count, word),
    do: "#{count} #{if(count > 1, do: plural(word), else: word)}"

  def plural(word) do
    cond do
      String.ends_with?(word, "y") && !(["ay", "ey", "oy", "uy"] |> Enum.any?(fn s -> String.ends_with?(word, s) end)) ->
        word |> String.replace_trailing("y", "ies")

      ["s", "x", "z", "sh", "ch"] |> Enum.any?(fn s -> String.ends_with?(word, s) end) ->
        word <> "es"

      true ->
        word <> "s"
    end
  end

  @doc """
  A smart stringification from any value
  """
  # def inspect(%Ecto.Changeset{valid?: false, errors: errors}), do: "Invalid changeset: #{errors |> Enum.map(fn e -> Stringx.inspect(e) end) |> Enum.join(", ")}"
  def inspect(value), do: Kernel.inspect(value)
end
