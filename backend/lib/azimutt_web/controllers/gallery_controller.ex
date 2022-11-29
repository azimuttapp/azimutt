defmodule AzimuttWeb.GalleryController do
  use AzimuttWeb, :controller
  alias Azimutt.Gallery
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html",
      samples: Gallery.list_samples(),
      seo: %{
        title: "The Database Schema Gallery",
        description: "Discover great database examples, for inspiration or learning. Azimutt has gathered great examples just for you!"
      }
    )
  end

  def show(conn, %{"slug" => slug}) do
    with {:ok, sample} <- Gallery.get_sample(slug),
         do:
           render(conn, "show.html",
             sample: sample,
             related: Gallery.related_samples(sample),
             seo: %{
               type: "article",
               title: sample.project.name <> " database schema",
               description: sample.description,
               image: Routes.url(conn) <> sample.banner
             }
           )
  end
end
