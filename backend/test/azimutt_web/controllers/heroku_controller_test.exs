defmodule AzimuttWeb.HerokuControllerTest do
  use AzimuttWeb.ConnCase, async: false
  alias Azimutt.Heroku
  alias Azimutt.Utils.Crypto
  import Azimutt.HerokuFixtures

  @sso_salt "salt"

  setup do
    Application.put_env(:heroku, :sso_salt, @sso_salt)
    on_exit(fn -> Application.delete_env(:heroku, :sso_salt) end)
  end

  # https://devcenter.heroku.com/articles/add-on-single-sign-on
  test "login and access heroku resource", %{conn: conn} do
    resource = resource_fixture()
    timestamp = System.os_time(:second)
    app = "demo-app"
    email = "user@mail.com"

    attrs = %{
      resource_id: resource.heroku_id,
      timestamp: timestamp,
      resource_token: Crypto.sha1("#{resource.heroku_id}:#{@sso_salt}:#{timestamp}"),
      app: app,
      email: email
    }

    conn = get(conn, Routes.heroku_path(conn, :show, resource.heroku_id))
    assert conn.status == 403

    conn = post(conn, Routes.heroku_path(conn, :login, attrs))
    assert redirected_to(conn, 302) =~ Routes.heroku_path(conn, :show, resource.heroku_id)

    conn = get(conn, Routes.heroku_path(conn, :show, resource.heroku_id))
    assert html_response(conn, 200) =~ "Hello Heroku user!"
    assert html_response(conn, 200) =~ app
    assert html_response(conn, 200) =~ email
    assert html_response(conn, 200) =~ resource.heroku_id

    Heroku.delete_resource(resource, DateTime.utc_now())

    conn = get(conn, Routes.heroku_path(conn, :show, resource.heroku_id))
    assert conn.status == 403
  end
end
