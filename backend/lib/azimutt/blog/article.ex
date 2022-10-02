defmodule Azimutt.Blog.Article do
  @moduledoc "A blog article"
  use TypedStruct
  alias Azimutt.Blog.Article
  alias Azimutt.Blog.Article.Author
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Markdown
  alias Azimutt.Utils.Result

  typedstruct enforce: true do
    field :path, String.t()
    field :id, String.t()
    field :title, String.t()
    field :excerpt, String.t()
    field :category, String.t()
    field :tags, list(String.t())
    field :author, Author.t()
    field :published, Date.t()
    field :markdown, String.t()
    field :html, String.t()
  end

  typedstruct module: Author, enforce: true do
    @moduledoc false
    field :name, String.t()
  end

  def authors do
    Map.new([
      {"loic", %Author{name: "Loïc Knuchel"}}
    ])
  end

  def get_author(id) do
    authors() |> Mapx.fetch(id)
  end

  def build(path, map) do
    id = path_to_id(path)
    published_str = path_to_date(path)

    with {:ok, title} when is_binary(title) <- map |> Mapx.fetch("title"),
         {:ok, excerpt} when is_binary(excerpt) <- map |> Mapx.fetch("excerpt"),
         {:ok, category} when is_binary(category) <- map |> Mapx.fetch("category"),
         {:ok, tags} <- map |> Mapx.fetch("tags") |> Result.flat_map(&build_tags/1),
         {:ok, author_id} when is_binary(author_id) <- map |> Mapx.fetch("author"),
         {:ok, %Author{} = author} <- author_id |> get_author,
         {:ok, published} <- published_str |> Date.from_iso8601(),
         {:ok, content} when is_binary(content) <- map |> Mapx.fetch("body"),
         markdown = preprocess_article_content(path, content),
         {:ok, html} when is_binary(html) <- Markdown.to_html(markdown),
         do:
           {:ok,
            %Article{
              path: path,
              id: id,
              title: title,
              excerpt: excerpt,
              category: category,
              tags: tags,
              author: author,
              published: published,
              markdown: markdown,
              html: html
            }}
  end

  def path_to_id(path) do
    path |> String.split("/") |> Enum.take(-1) |> Enum.at(0) |> String.replace_suffix(".md", "")
  end

  def path_to_date(path) do
    path |> String.split("/") |> Enum.drop(3) |> Enum.at(0) |> String.split("-") |> Enum.take(3) |> Enum.join("-")
  end

  defp build_tags(tags) when is_binary(tags), do: {:ok, tags |> String.split(",") |> Enum.map(&String.trim/1)}
  defp build_tags(tags) when is_list(tags), do: {:ok, tags}
  defp build_tags(tags) when is_nil(tags), do: {:ok, []}
  defp build_tags(tags), do: {:error, "Unexpected tags: #{inspect(tags)}"}

  defp preprocess_article_content(path, content) do
    # FIXME: don't know why http://localhost:4000/blog/2021-10-01-the-story-behind-azimutt/digital-singularity.jpg don't return image :(
    base_link = path |> String.split("/") |> Enum.drop(2) |> Enum.take(2) |> Enum.map_join(fn p -> "/#{p}" end)
    github = "https://github.com/azimuttapp/azimutt"

    content
    |> String.replace("{{base_link}}", base_link)
    |> String.replace("{{app_link}}", "/home")
    |> String.replace("{{roadmap_link}}", "#{github}/projects/1")
    |> String.replace("{{issues_link}}", "#{github}/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22")
    |> String.replace("{{feedback_link}}", "#{github}/discussions")
    |> String.replace("{{azimutt_twitter}}", "https://twitter.com/azimuttapp")
  end
end
