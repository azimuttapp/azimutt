defmodule AzimuttWeb.HerokuControllerTest do
  use AzimuttWeb.ConnCase, async: false
  alias Azimutt.Heroku
  alias Azimutt.Utils.Crypto
  import Azimutt.HerokuFixtures

  @sso_salt "salt"

  setup do
    Application.put_env(:azimutt, :heroku_sso_salt, @sso_salt)
    on_exit(fn -> Application.delete_env(:azimutt, :heroku_sso_salt) end)
  end

  # https://devcenter.heroku.com/articles/add-on-single-sign-on
  test "login and access heroku resource", %{conn: conn} do
    now_ts = System.os_time(:second)
    resource = resource_fixture()
    app = "demo-app"
    email = "user@mail.com"

    attrs = %{
      resource_id: resource.id,
      timestamp: now_ts,
      resource_token: Crypto.sha1("#{resource.id}:#{@sso_salt}:#{now_ts}"),
      app: app,
      email: email
    }

    conn = get(conn, Routes.heroku_path(conn, :show, resource.id))
    assert conn.status == 403

    conn = post(conn, Routes.heroku_path(conn, :login, attrs))
    assert redirected_to(conn, 302) =~ Routes.heroku_path(conn, :show, resource.id)

    conn = get(conn, Routes.heroku_path(conn, :show, resource.id))
    assert html_response(conn, 200) =~ "Azimutt Add-on"
    assert html_response(conn, 200) =~ email
    assert html_response(conn, 200) =~ resource.name

    Heroku.delete_resource(resource, DateTime.utc_now())

    conn = get(conn, Routes.heroku_path(conn, :show, resource.id))
    assert conn.status == 403
  end
end
