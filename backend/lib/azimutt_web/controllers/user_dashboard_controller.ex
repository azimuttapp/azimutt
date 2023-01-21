defmodule AzimuttWeb.UserDashboardController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  action_fallback AzimuttWeb.FallbackController

  def action(%Plug.Conn{assigns: %{current_user: current_user}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, current_user])
  end

  def index(conn, _params, current_user) do
    organization = Accounts.get_user_personal_organization(current_user)
    conn |> redirect(to: Routes.organization_path(conn, :show, organization))
  end
end
