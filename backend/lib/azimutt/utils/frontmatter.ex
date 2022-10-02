defmodule Azimutt.Utils.Frontmatter do
  @moduledoc """
  Frontmatter module, inspired by https://jekyllrb.com/docs/front-matter
  """
  alias Azimutt.Utils.Result

  def parse(content) do
    case content |> String.split(~r/\n-{3,}\n/, parts: 2) do
      [frontmatter, body] ->
        YamlElixir.read_from_string(frontmatter)
        |> Result.map(fn m -> m |> Map.put("body", body |> String.trim()) end)
        |> Result.map_error(fn err -> {:error, %{error: err, content: content}} end)

      _ ->
        {:error, :invalid_frontmatter}
    end
  end
end
