defmodule AzimuttWeb.UserOauthController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: %{info: user_info}}} = conn, %{"provider" => "github"}) do
    now = DateTime.utc_now()
    auth_method = "github"

    user_params = %{
      name: user_info.name || user_info.nickname,
      email: user_info.email,
      provider: "github",
      provider_uid: user_info.nickname,
      avatar: user_info.image,
      company: nil,
      location: user_info.location,
      description: user_info.description,
      github_username: user_info.nickname,
      twitter_username: nil
    }

    # FIXME: create a unique key (provider, provider_uid) => needs heroku provider_uid
    Accounts.get_user_by_provider(user_params.provider, user_params.provider_uid)
    |> Result.flat_map_error(fn _ ->
      Accounts.get_user_by_email(user_params.email)
      |> Result.tap(fn user -> user |> Accounts.set_user_provider(%{provider: "github", provider_uid: user_info.nickname}, now) end)
    end)
    |> Result.flat_map_error(fn _ ->
      Accounts.register_github_user(user_params, UserAuth.get_attribution(conn), now)
      |> Result.tap(fn user -> Accounts.send_email_confirmation(user, &Routes.user_confirmation_url(conn, :confirm, &1)) end)
    end)
    |> Result.map(fn user -> UserAuth.login_user_and_redirect(conn, user, auth_method) end)
    |> Result.or_else(callback(conn, %{}))
  end

  def callback(conn, _params) do
    conn |> put_flash(:error, "Authentication failed") |> redirect(to: Routes.website_path(conn, :index))
  end
end
