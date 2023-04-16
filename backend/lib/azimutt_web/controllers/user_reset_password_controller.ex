defmodule AzimuttWeb.UserResetPasswordController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController
  plug :get_user_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    Accounts.get_user_by_email(email)
    |> Result.tap(fn user -> Accounts.send_password_reset(user, &Routes.user_reset_password_url(conn, :edit, &1)) end)

    conn
    |> put_flash(:info, "We sent you an email to reset your password 👍️")
    |> redirect(to: Routes.user_session_path(conn, :new))
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Accounts.change_user_password(conn.assigns.user))
  end

  def update(conn, %{"user" => user_params}) do
    case Accounts.reset_user_password(conn.assigns.user, user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.user_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if user = Accounts.get_user_by_reset_password_token(token) do
      conn |> assign(:user, user) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: Routes.website_path(conn, :index))
      |> halt()
    end
  end
end
