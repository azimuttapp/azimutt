defmodule AzimuttWeb.Admin.UserController do
  use AzimuttWeb, :controller
  alias Azimutt.Admin
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html", users: Admin.list_users(1000))
  end

  def show(conn, %{"id" => user_id}) do
    with {:ok, user} <- Admin.get_user(user_id) do
      conn
      |> render("show.html",
        user: user,
        organizations: user.organizations,
        projects: user.organizations |> Enum.flat_map(fn o -> o.projects end),
        events: Admin.get_user_events(user.id, 1000)
      )
    end
  end
end
