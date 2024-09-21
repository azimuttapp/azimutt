defmodule AzimuttWeb.Api.MainController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.Api.FallbackController

  def index(conn, _params) do
    conn |> redirect(to: "/api/v1/swagger")
  end

  def aml_schema(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, File.read!("priv/static/aml_schema.json"))
  end
end
