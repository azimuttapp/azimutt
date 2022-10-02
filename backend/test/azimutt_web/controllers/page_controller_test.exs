defmodule AzimuttWeb.PageControllerTest do
  use AzimuttWeb.ConnCase

  @tag :skip
  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Never miss anomalies in your schema."
  end
end
