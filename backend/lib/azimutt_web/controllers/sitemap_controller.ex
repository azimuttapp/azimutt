defmodule AzimuttWeb.SitemapController do
  use AzimuttWeb, :controller
  alias Azimutt.Blog
  alias Azimutt.Gallery
  action_fallback AzimuttWeb.FallbackController
  plug :put_layout, false

  def index(conn, _params) do
    with {:ok, articles} <- Blog.get_articles(),
         {:ok, samples} <- Gallery.list_samples(),
         do: conn |> put_resp_content_type("text/xml") |> render("index.xml", articles: articles, samples: samples)
  end
end
