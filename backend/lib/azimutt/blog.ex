defmodule Azimutt.Blog do
  @moduledoc "Blog module"
  alias Azimutt.Blog.Article
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Frontmatter
  alias Azimutt.Utils.Result

  defp article_path, do: "priv/static/blog"

  def get_articles do
    # FIXME: add caching for articles
    IO.inspect("get_articles")
    paths = Path.wildcard("#{article_path()}/????-??-??-*/*.md")
    IO.inspect(paths, label: "paths")
    ids = paths |> Enum.map(&Article.path_to_id/1)
    IO.inspect(ids, label: "ids")
    articles = ids |> Enum.map(&get_article/1)
    IO.inspect(articles |> Enum.map(fn r -> r |> Result.map(fn a -> a.id end) end), label: "articles")
    result = articles |> Result.sequence()
    IO.inspect(result |> Result.map(fn r -> r |> Enum.map(fn a -> a.id end) end), label: "result")
    sorted = result |> Result.map(fn articles -> articles |> Enum.sort_by(& &1.published, {:desc, Date}) end)
    IO.inspect(sorted |> Result.map(fn r -> r |> Enum.map(fn a -> a.id end) end), label: "sorted")
    sorted
  end

  def get_article(id) do
    with {:ok, path} <- Path.wildcard("#{article_path()}/????-??-??-#{id}/#{id}.md") |> Enumx.one(),
         {:ok, content} <- File.read(path),
         {:ok, map} <- Frontmatter.parse(content),
         do: Article.build(path, map)
  end
end
