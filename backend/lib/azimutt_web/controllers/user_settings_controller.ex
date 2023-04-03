defmodule AzimuttWeb.UserSettingsController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def show(conn, _params) do
    current_user = conn.assigns.current_user

    conn |> render("show.html", user: current_user, infos_changeset: Accounts.change_user_infos(current_user))
  end

  def update_account(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.update_user_infos(current_user, user_params, now)
    |> Result.fold(
      fn changeset_error -> conn |> render("show.html", user: current_user, infos_changeset: changeset_error) end,
      fn _ -> conn |> put_flash(:info, "Infos updated!") |> redirect(to: Routes.user_settings_path(conn, :show)) end
    )
  end

  def update_email(conn, _params) do
    conn |> redirect(to: Routes.user_settings_path(conn, :show))
  end

  def update_password(conn, _params) do
    conn |> redirect(to: Routes.user_settings_path(conn, :show))
  end
end
