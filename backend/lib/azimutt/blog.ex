defmodule Azimutt.Blog do
  @moduledoc "Blog module"
  alias Azimutt.Blog.Article
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Frontmatter
  alias Azimutt.Utils.Result

  defp article_path, do: "priv/static/blog"

  def get_articles do
    # FIXME: add caching for articles
    Path.wildcard("#{article_path()}/????-??-??-*/*.md")
    |> Enum.map(&Article.path_to_id/1)
    |> Enum.map(&get_article/1)
    |> Result.sequence()
    |> Result.map(fn articles -> articles |> Enum.sort_by(& &1.published, {:desc, Date}) end)
  end

  def get_article(id) do
    with {:ok, path} <- Path.wildcard("#{article_path()}/????-??-??-#{id}/#{id}.md") |> Enumx.one(),
         {:ok, content} <- File.read(path),
         {:ok, map} <- Frontmatter.parse(content),
         do: Article.build(path, map)
  end
end
