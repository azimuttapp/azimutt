defmodule AzimuttWeb.HerokuControllerTest do
  use AzimuttWeb.ConnCase

  test "POST /heroku/resources", %{conn: conn} do
    conn = post(conn, Routes.heroku_path(conn, :create))
    assert json_response(conn, 200) == %{"ok" => "ok"}
  end

  test "DELETE /heroku/resources/:id", %{conn: conn} do
    conn = delete(conn, Routes.heroku_path(conn, :delete, "1"))
    assert json_response(conn, 200) == %{"ok" => "ok"}
  end
end
