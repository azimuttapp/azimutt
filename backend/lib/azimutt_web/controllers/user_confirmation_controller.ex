defmodule AzimuttWeb.UserConfirmationController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  action_fallback AzimuttWeb.FallbackController

  def new(conn, _params) do
    {now, current_user} = {DateTime.utc_now(), conn.assigns.current_user}

    if current_user.confirmed_at do
      conn |> redirect(to: Routes.user_dashboard_path(conn, :index))
    else
      conn |> render("new.html", user: current_user, now: now)
    end
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    Accounts.send_email_confirmation(current_user, &Routes.user_confirmation_url(conn, :confirm, &1))

    referer =
      conn
      |> get_req_header("referer")
      |> Enum.filter(fn h -> h |> String.contains?(Azimutt.config(:host)) end)
      |> List.first()

    if params["redirect"] == "referer" && referer do
      conn
      |> put_flash(:info, "Your email confirmation is sent, click the link inside to confirm your email.")
      |> redirect(external: referer)
    else
      conn
      |> put_flash(:info, "Your email confirmation is sent, click the link inside to confirm your email.")
      |> redirect(to: Routes.user_confirmation_path(conn, :new))
    end
  end

  def confirm(conn, %{"token" => token}) do
    {now, current_user} = {DateTime.utc_now(), conn.assigns.current_user}

    if current_user.confirmed_at do
      conn |> redirect(to: Routes.user_dashboard_path(conn, :index))
    else
      case Accounts.confirm_user(current_user, token, now) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Email successfully confirmed.")
          |> redirect(to: Routes.user_dashboard_path(conn, :index))

        :error ->
          # If there is a current user and the account was already confirmed,
          # then odds are that the confirmation link was already visited, either
          # by some automation or by the user themselves, so we redirect without
          # a warning message.
          case conn.assigns do
            %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
              conn |> redirect(to: Routes.user_dashboard_path(conn, :index))

            %{} ->
              conn
              |> put_flash(:error, "User confirmation link is invalid or it has expired.")
              |> redirect(to: Routes.user_confirmation_path(conn, :new))
          end
      end
    end
  end
end
