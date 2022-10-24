defmodule Azimutt.Gallery do
  @moduledoc "Gallery module"
  alias Azimutt.Gallery.Example
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Frontmatter
  alias Azimutt.Utils.Phoenix
  alias Azimutt.Utils.Result

  defp example_path, do: "priv/static/gallery"

  def get_examples do
    # FIXME: add caching for examples
    Path.wildcard("#{example_path()}/*/*.md")
    |> Enum.reject(&Phoenix.has_digest/1)
    |> Enum.map(&Example.path_to_id/1)
    |> Enum.map(&get_example/1)
    |> Result.sequence()
    |> Result.map(fn examples -> examples |> Enum.sort_by(& &1.tables) end)
  end

  def get_example(id) do
    with {:ok, path} <- Path.wildcard("#{example_path()}/#{id}/#{id}.md") |> Enumx.one(),
         {:ok, content} <- File.read(path),
         {:ok, map} <- Frontmatter.parse(content),
         do: Example.build(path, map)
  end

  # Get 3 other examples
  def get_related_examples(example) do
    get_examples()
    |> Result.map(fn examples ->
      examples |> Enum.filter(fn e -> e.id != example.id end) |> Enum.shuffle() |> Enum.take(3)
    end)
  end
end
