defmodule AzimuttWeb.UserSessionController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  def new(conn, _params) do
    conn |> render("new.html", error_message: nil)
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn |> render("new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn |> UserAuth.log_out_user()
  end

  # a trick to redirect to the specified url after login
  def redirect_to(conn, %{"url" => url}) do
    conn |> redirect(external: url)
  end
end
