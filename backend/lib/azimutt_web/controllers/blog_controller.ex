defmodule AzimuttWeb.BlogController do
  use AzimuttWeb, :controller
  alias Azimutt.Blog
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    with {:ok, articles} <- Blog.list_articles(),
         do:
           render(conn, "index.html",
             articles: articles,
             seo: %{
               title: "The Azimutt Blog",
               description:
                 "Hi! We are Samir & Loïc. We're building a Next-Gen ERD to help understand real world databases, with cool UI and privacy focus. You can read about our journey and what we've learnt along the way on this blog."
             }
           )
  end

  def show(conn, %{"id" => id}) do
    with {:ok, article} <- Blog.get_article(id),
         do:
           render(conn, "show.html",
             article: article,
             related: Blog.related_articles(article) |> Result.or_else([]),
             seo: %{
               type: "article",
               title: article.title,
               description: article.excerpt,
               image: Routes.url(conn) <> article.banner
             }
           )
  end
end
