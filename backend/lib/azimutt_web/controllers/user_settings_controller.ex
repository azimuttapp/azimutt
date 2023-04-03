defmodule AzimuttWeb.UserSettingsController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def show(conn, _params) do
    current_user = conn.assigns.current_user
    conn |> show_html(current_user)
  end

  def update_account(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.update_user_infos(current_user, user_params, now)
    |> Result.fold(
      fn changeset_error -> conn |> show_html(current_user, infos_changeset: changeset_error) end,
      fn _ -> conn |> put_flash(:info, "Infos updated!") |> redirect(to: Routes.user_settings_path(conn, :show)) end
    )
  end

  def update_email(conn, _params) do
    conn |> redirect(to: Routes.user_settings_path(conn, :show))
  end

  def update_password(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.update_user_password(current_user, user_params["current_password"], user_params)
    |> Result.fold(
      fn changeset_error -> conn |> show_html(current_user, password_changeset: changeset_error) end,
      fn user ->
        conn
        |> AzimuttWeb.UserAuth.login_user(user, "update_password")
        |> put_flash(:info, "Password updated!")
        |> redirect(to: Routes.user_settings_path(conn, :show))
      end
    )
  end

  defp show_html(conn, user, options \\ []) do
    defaults = [
      infos_changeset: Accounts.change_user_infos(user),
      password_changeset: Accounts.change_user_password(user)
    ]

    %{infos_changeset: infos_changeset, password_changeset: password_changeset} = Keyword.merge(defaults, options) |> Enum.into(%{})

    conn
    |> render("show.html",
      user: user,
      infos_changeset: infos_changeset,
      password_changeset: password_changeset
    )
  end
end
