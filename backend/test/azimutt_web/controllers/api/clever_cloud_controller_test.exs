defmodule AzimuttWeb.Api.CleverCloudControllerTest do
  use AzimuttWeb.ConnCase, async: false

  @addon_id "azimutt-test"
  @password "pass"
  @token Plug.BasicAuth.encode_basic_auth(@addon_id, @password)

  setup do
    Application.put_env(:azimutt, :clever_cloud_addon_id, @addon_id)
    Application.put_env(:azimutt, :clever_cloud_password, @password)

    on_exit(fn ->
      Application.delete_env(:azimutt, :clever_cloud_addon_id)
      Application.delete_env(:azimutt, :clever_cloud_password)
    end)
  end

  # cf https://www.clever-cloud.com/doc/extend/add-ons-api/#provisioning
  test "provision, change plan and deprovision a resource", %{conn: conn} do
    resource = %{
      addon_id: "addon_xxx",
      owner_id: "orga_xxx",
      owner_name: "My Company",
      user_id: "user_yyy",
      plan: "basic",
      region: "EU",
      callback_url: "https://api.clever-cloud.com/v2/vendor/apps/addon_xxx",
      logplex_token: "logtoken_yyy",
      options: nil
    }

    conn = conn |> authed() |> post(Routes.clever_cloud_path(conn, :create, resource))
    id = json_response(conn, 200)["id"]
    assert json_response(conn, 200) == %{"id" => id, "config" => %{}, "message" => "Your Azimutt add-on is now provisioned."}

    conn = conn |> recycle() |> authed() |> post(Routes.clever_cloud_path(conn, :update, id, %{plan: "pro"}))
    assert json_response(conn, 200) == %{"id" => id, "config" => %{}, "message" => "Azimutt plan changed from basic to pro."}

    conn = conn |> recycle() |> authed() |> delete(Routes.clever_cloud_path(conn, :delete, id))
    assert conn.status == 204

    conn = conn |> recycle() |> authed() |> delete(Routes.clever_cloud_path(conn, :delete, id))
    assert conn.status == 410
  end

  defp authed(conn), do: conn |> put_req_header("authorization", @token)
end
