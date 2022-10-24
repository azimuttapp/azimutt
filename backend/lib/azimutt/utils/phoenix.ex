defmodule Azimutt.Utils.Phoenix do
  @moduledoc false

  def has_digest(path) do
    # when doing digest, phoenix generate files with a hash at the end, this function identify them
    # hash has a length of 32, so if last segment has this length, it's probably a hash
    last_segment = path |> String.split("/") |> Enum.take(-1) |> Enum.at(0)
    last_word = last_segment |> String.split("-") |> Enum.take(-1) |> Enum.at(0)
    no_extension = last_word |> String.split(".") |> Enum.drop(-1) |> Enum.join(".")
    no_extension |> String.length() == 32
  end
end
