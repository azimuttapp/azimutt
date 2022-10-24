defmodule Azimutt.Gallery.Example do
  @moduledoc "A gallery example"
  use TypedStruct
  alias Azimutt.Gallery.Example
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Markdown
  alias Azimutt.Utils.Result

  typedstruct enforce: true do
    field :path, String.t()
    field :id, String.t()
    field :icon, String.t()
    field :color, String.t()
    field :name, String.t()
    field :website, String.t()
    field :banner, String.t()
    field :excerpt, String.t()
    field :tables, integer()
    field :project_url, String.t()
    field :published, Date.t()
    field :markdown, String.t()
    field :html, String.t()
  end

  def build(path, map) do
    id = path_to_id(path)

    with {:ok, icon} when is_binary(icon) <- map |> Mapx.fetch("icon"),
         {:ok, color} when is_binary(color) <- map |> Mapx.fetch("color"),
         {:ok, name} when is_binary(name) <- map |> Mapx.fetch("name"),
         {:ok, website} when is_binary(website) <- map |> Mapx.fetch("website"),
         {:ok, banner} when is_binary(banner) <- map |> Mapx.fetch("banner"),
         {:ok, excerpt} when is_binary(excerpt) <- map |> Mapx.fetch("excerpt"),
         {:ok, tables} when is_integer(tables) <- map |> Mapx.fetch("tables"),
         {:ok, project_url} when is_binary(project_url) <- map |> Mapx.fetch("project-url"),
         {:ok, published_str} when is_binary(published_str) <- map |> Mapx.fetch("published"),
         {:ok, published} <- published_str |> Date.from_iso8601(),
         {:ok, body} when is_binary(body) <- map |> Mapx.fetch("body"),
         markdown = preprocess_example_content(path, body),
         {:ok, html} when is_binary(html) <- Markdown.to_html(markdown),
         do:
           {:ok,
            %Example{
              path: path,
              id: id,
              icon: icon,
              color: color,
              name: name,
              website: website,
              banner: banner |> String.replace("{{base_link}}", base_link(path)),
              excerpt: excerpt,
              tables: tables,
              project_url: project_url |> String.replace("{{base_link}}", base_link(path)),
              published: published,
              markdown: markdown,
              html: html
            }}
  end

  def path_to_id(path), do: path |> String.split("/") |> Enum.take(-1) |> Enum.at(0) |> String.replace_suffix(".md", "")
  defp base_link(path), do: path |> String.split("/") |> Enum.drop(2) |> Enum.take(2) |> Enum.map_join(fn p -> "/#{p}" end)

  defp preprocess_example_content(path, content) do
    github = "https://github.com/azimuttapp/azimutt"

    content
    |> String.replace("{{base_link}}", base_link(path))
    |> String.replace("{{app_link}}", "/home")
    |> String.replace("{{roadmap_link}}", "#{github}/projects/1")
    |> String.replace("{{issues_link}}", "#{github}/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22")
    |> String.replace("{{feedback_link}}", "#{github}/discussions")
    |> String.replace("{{azimutt_twitter}}", "https://twitter.com/azimuttapp")
  end
end
