defmodule AzimuttWeb.UserSessionController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Services.RecaptchaSrv
  alias Azimutt.Utils.Result
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  def new(conn, _params) do
    conn |> render("new.html", error_message: nil)
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params} = params) do
    RecaptchaSrv.validate(params["g-recaptcha-response"])
    |> Result.flat_map(fn _ -> Accounts.get_user_by_email_and_password(email, password) end)
    |> Result.fold(
      fn err -> conn |> render("new.html", error_message: if(err == :not_found, do: "Email or Password invalid.", else: err)) end,
      fn user -> conn |> UserAuth.login_user_and_redirect(user, "password", user_params) end
    )
  end

  def delete(conn, _params) do
    conn |> UserAuth.log_out_user()
  end

  # a trick to redirect to the specified url after login
  def redirect_to(conn, %{"url" => url}) do
    conn |> redirect(external: url)
  end
end
