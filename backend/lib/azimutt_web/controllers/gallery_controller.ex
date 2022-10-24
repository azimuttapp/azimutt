defmodule AzimuttWeb.GalleryController do
  use AzimuttWeb, :controller
  alias Azimutt.Gallery
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    with {:ok, examples} <- Gallery.get_examples(),
         do:
           render(conn, "index.html",
             examples: examples,
             seo: %{
               title: "Database Schema Gallery",
               description:
                 "Discover great database examples, for inspiration or learning. Azimutt has gathered great examples just for you!"
             }
           )
  end

  # TODO: show real projects (stored in orga) with is_public flag
  def show(conn, %{"id" => id}) do
    with {:ok, example} <- Gallery.get_example(id),
         {:ok, related_examples} <- Gallery.get_related_examples(example),
         do:
           render(conn, "show.html",
             example: example,
             related_examples: related_examples,
             seo: %{
               type: "article",
               title: example.name <> " database schema",
               description: example.excerpt,
               image: Routes.url(conn) <> example.banner
             }
           )
  end
end
