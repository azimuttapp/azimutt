defmodule Azimutt.Blog.Article do
  @moduledoc "A blog article"
  use TypedStruct
  alias Azimutt.Blog.Article
  alias Azimutt.Blog.Article.Author
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Markdown
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  typedstruct enforce: true do
    field :path, String.t()
    field :id, String.t()
    field :title, String.t()
    field :banner, String.t()
    field :excerpt, String.t()
    field :category, String.t()
    field :keywords, list(String.t())
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
    authors() |> Map.get(id, %Author{name: id})
  end

  def build(path, map) do
    id = path_to_id(path)
    published_str = path_to_date(path)

    with {:ok, title} when is_binary(title) <- map |> Mapx.fetch("title"),
         {:ok, banner} when is_binary(banner) <- map |> Mapx.fetch("banner"),
         {:ok, excerpt} when is_binary(excerpt) <- map |> Mapx.fetch("excerpt"),
         {:ok, category} when is_binary(category) <- map |> Mapx.fetch("category"),
         keywords = map |> Map.fetch("keywords") |> Result.flat_map(&build_list/1) |> Result.or_else([]),
         {:ok, author_id} when is_binary(author_id) <- map |> Mapx.fetch("author"),
         author = author_id |> get_author,
         {:ok, published} <- published_str |> Date.from_iso8601(),
         {:ok, body} when is_binary(body) <- map |> Mapx.fetch("body"),
         markdown = Markdown.preprocess(body, path),
         {:ok, html} when is_binary(html) <- Markdown.to_html(markdown),
         do:
           {:ok,
            %Article{
              path: path,
              id: id,
              title: title,
              banner: banner |> String.replace("{{base_link}}", Markdown.base_link(path)),
              excerpt: excerpt,
              category: category,
              keywords: keywords,
              author: author,
              published: published,
              markdown: markdown,
              html: html
            }}
  end

  def path_to_id(path), do: path |> String.split("/") |> Enum.take(-1) |> Enum.at(0) |> String.replace_suffix(".md", "")
  def path_to_date(path), do: path |> String.split("/") |> Enum.drop(3) |> Enum.at(0) |> String.split("-") |> Enum.take(3) |> Enum.join("-")

  defp build_list(value) when is_binary(value), do: {:ok, value |> String.split(",") |> Enum.map(&String.trim/1)}
  defp build_list(value) when is_list(value), do: {:ok, value}
  defp build_list(value) when is_nil(value), do: {:ok, []}
  defp build_list(value), do: {:error, "Unexpected list value: #{Stringx.inspect(value)}"}
end
