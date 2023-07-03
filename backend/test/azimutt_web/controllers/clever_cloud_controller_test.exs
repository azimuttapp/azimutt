defmodule AzimuttWeb.CleverCloudControllerTest do
  use AzimuttWeb.ConnCase, async: false
  alias Azimutt.CleverCloud
  alias Azimutt.Utils.Crypto
  import Azimutt.CleverCloudFixtures

  @sso_salt "salt"

  setup do
    Application.put_env(:azimutt, :clever_cloud_sso_salt, @sso_salt)
    on_exit(fn -> Application.delete_env(:azimutt, :clever_cloud_sso_salt) end)
  end

  # https://www.clever-cloud.com/doc/extend/add-ons-api/#sso
  test "login and access Clever Cloud resource", %{conn: conn} do
    now_ts = System.os_time(:second)
    resource = clever_cloud_resource_fixture()
    email = "user@mail.com"

    conn = get(conn, Routes.clever_cloud_path(conn, :show, resource.id))
    assert conn.status == 403

    conn =
      post(
        conn,
        Routes.clever_cloud_path(conn, :login, %{
          id: resource.id,
          token: Crypto.sha1("#{resource.id}:#{@sso_salt}:#{now_ts}"),
          timestamp: now_ts,
          email: email
        })
      )

    assert redirected_to(conn, 302) =~ Routes.clever_cloud_path(conn, :show, resource.id)

    {:ok, resource} = CleverCloud.get_resource(resource.id)
    conn = get(conn, Routes.clever_cloud_path(conn, :show, resource.id))
    assert html_response(conn, 200) =~ "Azimutt Add-on"
    assert html_response(conn, 200) =~ email

    CleverCloud.delete_resource(resource, DateTime.utc_now())

    conn = get(conn, Routes.clever_cloud_path(conn, :show, resource.id))
    assert conn.status == 403
  end
end
