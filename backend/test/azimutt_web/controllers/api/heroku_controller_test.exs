defmodule AzimuttWeb.Api.HerokuControllerTest do
  use AzimuttWeb.ConnCase, async: false

  @addon_id "azimutt-test"
  @password "pass"
  @token Plug.BasicAuth.encode_basic_auth(@addon_id, @password)

  setup do
    Application.put_env(:azimutt, :heroku_addon_id, @addon_id)
    Application.put_env(:azimutt, :heroku_password, @password)

    on_exit(fn ->
      Application.delete_env(:azimutt, :heroku_addon_id)
      Application.delete_env(:azimutt, :heroku_password)
    end)
  end

  # cf https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request
  test "provision, change plan and deprovision a resource", %{conn: conn} do
    id = "e5a2235b-7cd1-4e15-89ba-d7b5c3ccfe38"

    resource = %{
      uuid: id,
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
    assert json_response(conn, 200) == %{"id" => id, "message" => "Your Azimutt add-on is now provisioned."}

    conn = conn |> recycle() |> authed() |> post(Routes.heroku_path(conn, :create, resource))
    assert json_response(conn, 200) == %{"id" => id, "message" => "This resource was already created."}

    conn = conn |> recycle() |> authed() |> put(Routes.heroku_path(conn, :update, id, %{plan: "pro"}))
    assert json_response(conn, 200) == %{"id" => id, "message" => "Azimutt plan changed from basic to pro."}

    conn = conn |> recycle() |> authed() |> delete(Routes.heroku_path(conn, :delete, id))
    assert conn.status == 204

    conn = conn |> recycle() |> authed() |> delete(Routes.heroku_path(conn, :delete, id))
    assert conn.status == 410
  end

  defp authed(conn), do: conn |> put_req_header("authorization", @token)
end
