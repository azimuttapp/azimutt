defmodule AzimuttWeb.WebsiteControllerTest do
  use AzimuttWeb.ConnCase

  setup do
    Application.put_env(:azimutt, :skip_public_site, false)

    on_exit(fn ->
      Application.delete_env(:azimutt, :skip_public_site)
    end)
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, Routes.website_path(conn, :index))
    assert html_response(conn, 200) =~ "Dive in your database, at any level"
  end
end
