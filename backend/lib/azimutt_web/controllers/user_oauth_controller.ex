defmodule AzimuttWeb.UserOauthController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: %{info: user_info}}} = conn, %{"provider" => "github"}) do
    now = DateTime.utc_now()

    user_params = %{
      name: user_info.name || user_info.nickname,
      email: user_info.email,
      # FIXME
      provider: "github",
      # FIXME
      provider_uid: user_info.nickname,
      avatar: user_info.image,
      # FIXME
      company: nil,
      location: user_info.location,
      description: user_info.description,
      github_username: user_info.nickname,
      # FIXME
      twitter_username: nil
    }

    case Accounts.fetch_or_create_user(user_params, now) do
      {:ok, user} ->
        UserAuth.log_in_user(conn, user)

      _ ->
        conn
        |> put_flash(:error, "Authentication failed")
        |> redirect(to: "/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: "/")
  end
end
