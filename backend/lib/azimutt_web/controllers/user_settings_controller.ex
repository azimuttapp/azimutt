defmodule AzimuttWeb.UserSettingsController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Organizations
  action_fallback AzimuttWeb.FallbackController

  def show(conn, _params) do
    current_user = conn.assigns.current_user

    conn |> render("show.html", user: current_user)
  end

  def update_account(conn, _params) do
    conn |> redirect(to: Routes.user_settings_path(conn, :show))
  end

  def update_email(conn, _params) do
    conn |> redirect(to: Routes.user_settings_path(conn, :show))
  end

  def update_password(conn, _params) do
    conn |> redirect(to: Routes.user_settings_path(conn, :show))
  end
end
