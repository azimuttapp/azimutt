defmodule AzimuttWeb.FallbackControllerTest do
  use AzimuttWeb.ConnCase

  test "GET /404", %{conn: conn} do
    conn = get(conn, "/toto")
    assert html_response(conn, 404) =~ "Page not found"
    conn = get(conn, "/toto/titi")
    assert html_response(conn, 404) =~ "Page not found"
  end
end
