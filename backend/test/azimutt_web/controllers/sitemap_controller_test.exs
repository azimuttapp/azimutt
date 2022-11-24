defmodule AzimuttWeb.SitemapControllerTest do
  use AzimuttWeb.ConnCase

  @tag :skip
  test "GET /sitemap.xml", %{conn: conn} do
    conn = get(conn, "/sitemap.xml")
    assert html_response(conn, 200) =~ "/blog"
  end
end
