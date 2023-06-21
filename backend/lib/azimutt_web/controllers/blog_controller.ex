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

  def show(conn, %{"article_id" => article_id}) do
    with {:ok, article} <- Blog.get_article(article_id),
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

  # same as index but to preview cards
  def cards(conn, _params) do
    with {:ok, articles} <- Blog.list_articles(),
         do: render(conn, "cards.html", articles: articles, seo: %{title: "Cards", description: "Show all cards"})
  end
end
