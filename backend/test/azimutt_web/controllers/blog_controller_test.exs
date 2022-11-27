defmodule AzimuttWeb.BlogControllerTest do
  use AzimuttWeb.ConnCase

  test "GET /blog", %{conn: conn} do
    conn = get(conn, Routes.blog_path(conn, :index))
    assert html_response(conn, 200) =~ "The Azimutt Blog"
    assert html_response(conn, 200) =~ "Azimutt v2"
  end

  test "GET /blog/:id", %{conn: conn} do
    conn = get(conn, Routes.blog_path(conn, :show, "azimutt-v2"))
    assert html_response(conn, 200) =~ "Azimutt v2"
    assert html_response(conn, 200) =~ "Very happy to see you there to share with us this big moment."
  end
end
