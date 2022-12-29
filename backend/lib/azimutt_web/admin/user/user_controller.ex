defmodule AzimuttWeb.Admin.UserController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    users = Azimutt.Admin.list_users()

    render(conn, "index.html", users: users)
  end

  def show(conn, %{"id" => user_id}) do
    events = Azimutt.Admin.get_user_events(user_id)

    with {:ok, user} <- Azimutt.Admin.get_user(user_id) do
      render(conn, "show.html", user: user, events: events)
    end
  end
end
