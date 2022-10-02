defmodule AzimuttWeb.BlogController do
  use AzimuttWeb, :controller
  alias Azimutt.Blog

  def index(conn, _params) do
    with {:ok, articles} <- Blog.get_articles(),
         do: render(conn, "index.html", articles: articles)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, article} <- Blog.get_article(id),
         do: render(conn, "show.html", article: article)
  end
end
