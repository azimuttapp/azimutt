defmodule AzimuttWeb.HerokuControllerTest do
  use AzimuttWeb.ConnCase, async: false
  alias Azimutt.Utils.Crypto

  @addon_id "azimutt-test"
  @password "pass"
  @token Plug.BasicAuth.encode_basic_auth(@addon_id, @password)
  @sso_salt "17af74ceed6932ecdfaa8267bb582047bfb2c12c"

  setup do
    Application.put_env(:heroku, :addon_id, @addon_id)
    Application.put_env(:heroku, :password, @password)
    Application.put_env(:heroku, :sso_salt, @sso_salt)

    on_exit(fn ->
      Application.delete_env(:heroku, :addon_id)
      Application.delete_env(:heroku, :password)
      Application.delete_env(:heroku, :sso_salt)
    end)
  end

  # https://devcenter.heroku.com/articles/add-on-single-sign-on
  test "POST /heroku/login", %{conn: conn} do
    resource_id = "ad629e8e-6748-41e9-b0ea-5e9856f5591a"
    timestamp = System.os_time(:second)

    attrs = %{
      resource_id: resource_id,
      timestamp: timestamp,
      resource_token: Crypto.sha1("#{resource_id}:#{@sso_salt}:#{timestamp}"),
      email: "user@mail.com"
    }

    conn = post(conn, Routes.heroku_path(conn, :login, attrs))
    assert redirected_to(conn, 302) =~ Routes.user_dashboard_path(conn, :index)
  end

  # cf https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request
  test "provision and deprovision a resource", %{conn: conn} do
    heroku_id = "e5a2235b-7cd1-4e15-89ba-d7b5c3ccfe38"

    resource = %{
      uuid: heroku_id,
      name: "acme-inc-primary-database",
      callback_url: "https://api.heroku.com/addons/816de863-66ce-42ff-8b1d-b8fd7d713ba0",
      oauth_grant: %{
        code: "c85cdb57-1037-4c68-a2a7-d759eb92dab1",
        expires_at: "2016-03-03T18:01:31-0800",
        type: "authorization_code"
      },
      region: "amazon-web-services::us-east-1",
      plan: "basic",
      options: %{foo: "bar", baz: "true"}
    }

    conn = conn |> authed() |> post(Routes.heroku_path(conn, :create, resource))
    assert json_response(conn, 200) == %{"id" => heroku_id, "message" => "Your add-on is now provisioned."}

    conn = conn |> recycle() |> authed() |> post(Routes.heroku_path(conn, :create, resource))
    assert json_response(conn, 200) == %{"id" => heroku_id, "message" => "This resource was already created."}

    conn = conn |> recycle() |> authed() |> put(Routes.heroku_path(conn, :update, heroku_id, %{plan: "pro"}))
    assert json_response(conn, 200) == %{"id" => heroku_id, "message" => "Plan updated to pro."}

    conn = conn |> recycle() |> authed() |> delete(Routes.heroku_path(conn, :delete, heroku_id))
    assert conn.status == 204

    conn = conn |> recycle() |> authed() |> delete(Routes.heroku_path(conn, :delete, heroku_id))
    assert conn.status == 410
  end

  defp authed(conn), do: conn |> put_req_header("authorization", @token)
end
