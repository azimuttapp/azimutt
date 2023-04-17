defmodule AzimuttWeb.UserDashboardController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    organization = Accounts.get_user_default_organization(current_user)
    conn |> redirect(to: Routes.organization_path(conn, :show, organization))
  end
end
