defmodule Azimutt.Utils.Markdown do
  @moduledoc "Functions to manipulate markdown"
  alias Azimutt.Utils.Slugme

  def to_html(markdown) do
    with {:ok, html, _} <-
           Earmark.as_html(markdown,
             registered_processors: [
               {"h1", &add_id_att/1},
               {"h2", &add_id_att/1},
               {"h3", &add_id_att/1},
               {"h4", &add_id_att/1},
               {"h5", &add_id_att/1},
               {"h6", &add_id_att/1}
             ]
           ),
         do: {:ok, html}
  end

  def preprocess(content, path) do
    github = "https://github.com/azimuttapp/azimutt"

    content
    |> String.replace("{{base_link}}", base_link(path))
    |> String.replace("{{app_link}}", "/home")
    |> String.replace("{{roadmap_link}}", "#{github}/projects/1")
    |> String.replace("{{issues_link}}", "#{github}/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22")
    |> String.replace("{{feedback_link}}", "#{github}/discussions")
    |> String.replace("{{azimutt_twitter}}", "https://twitter.com/azimuttapp")
    |> String.replace("{{azimutt_email}}", "contact@azimutt.app")
  end

  def base_link(path), do: path |> String.split("/") |> Enum.drop(2) |> Enum.take(2) |> Enum.map_join(fn p -> "/#{p}" end)

  defp add_id_att({_tag, _atts, content, _meta} = node) do
    Earmark.AstTools.merge_atts_in_node(node, id: Slugme.slugify(content_to_string(content)))
  end

  defp content_to_string(content) when is_list(content) do
    content |> Enum.map_join(" ", &content_to_string/1)
  end

  defp content_to_string(content) when is_binary(content) do
    content
  end
end
