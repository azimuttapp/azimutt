defmodule Azimutt.Blog.ArticleTest do
  use Azimutt.DataCase
  alias Azimutt.Blog.Article
  alias Azimutt.Blog.Article.Author

  describe "article" do
    test "path_to_id" do
      assert "the-story-behind-azimutt" =
               Article.path_to_id("priv/static/blog/2021-10-01-the-story-behind-azimutt/the-story-behind-azimutt.md")
    end

    test "path_to_date" do
      assert "2021-10-01" = Article.path_to_date("priv/static/blog/2021-10-01-the-story-behind-azimutt/the-story-behind-azimutt.md")
    end

    test "build" do
      path = "priv/static/blog/2021-10-01-the-story-behind-azimutt/the-story-behind-azimutt.md"

      input = %{
        "title" => "My title",
        "banner" => "{{base_link}}/home.jpg",
        "excerpt" => "Awesome post!",
        "category" => "news",
        "tags" => "announce, v2",
        "author" => "loic",
        "body" => "Go [home]({{base_link}}/home.jpg), it's late"
      }

      result = %Article{
        path: path,
        id: "the-story-behind-azimutt",
        title: "My title",
        banner: "/blog/2021-10-01-the-story-behind-azimutt/home.jpg",
        excerpt: "Awesome post!",
        category: "news",
        tags: ["announce", "v2"],
        author: %Author{name: "Loïc Knuchel"},
        published: Date.from_iso8601!("2021-10-01"),
        markdown: "Go [home](/blog/2021-10-01-the-story-behind-azimutt/home.jpg), it's late",
        html: "<p>\nGo <a href=\"/blog/2021-10-01-the-story-behind-azimutt/home.jpg\">home</a>, it’s late</p>\n"
      }

      assert {:ok, ^result} = Article.build(path, input)
    end
  end
end
