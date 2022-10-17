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
