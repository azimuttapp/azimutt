defmodule AzimuttWeb.WebsiteControllerTest do
  use AzimuttWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, Routes.website_path(conn, :index))
    assert html_response(conn, 200) =~ "Search on tables, columns, relations and comments."
  end
end
