defmodule AzimuttWeb.GalleryControllerTest do
  use AzimuttWeb.ConnCase

  test "GET /gallery", %{conn: conn} do
    conn = get(conn, Routes.gallery_path(conn, :index))
    assert html_response(conn, 200) =~ "The Database Schema Gallery"
    assert html_response(conn, 200) =~ "A very simple schema, with only 4 tables to start playing with all the Azimutt features."
  end

  test "GET /gallery/:id", %{conn: conn} do
    conn = get(conn, Routes.gallery_path(conn, :show, "basic"))
    assert html_response(conn, 200) =~ "Basic database schema"
    assert html_response(conn, 200) =~ "This database schema is not the most innovative one."
  end
end
