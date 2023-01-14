defmodule AzimuttWeb.Admin.EmailController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  # use `index` for path but it's more a `new` resource
  def index(conn, _params) do
    conn |> render("new.html")
  end

  def create(conn, params) do
    # IO.inspect(params, label: "params")
    conn
    |> put_flash(:info, "TODO: send email")
    |> redirect(to: Routes.admin_email_path(conn, :index))
  end
end
