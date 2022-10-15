defmodule AzimuttWeb.SitemapController do
  use AzimuttWeb, :controller
  plug :put_layout, false
  alias Azimutt.Blog

  def index(conn, _params) do
    with {:ok, articles} <- Blog.get_articles(),
         do: conn |> put_resp_content_type("text/xml") |> render("index.xml", articles: articles)
  end
end
