defmodule AzimuttWeb.UserOauthController do
  use AzimuttWeb, :controller
  plug Ueberauth
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  def callback(conn, %{"provider" => "github"}) do
    now = DateTime.utc_now()
    auth_info = conn.assigns.ueberauth_auth
    provider = auth_info.provider |> Atom.to_string()
    provider_uid = auth_info.uid |> Integer.to_string()
    user = auth_info.extra.raw_info.user

    user_params = %{
      name: user["name"] || user["login"],
      email: user["email"],
      provider: provider,
      provider_uid: provider_uid,
      provider_data: to_map(auth_info),
      avatar: user["avatar_url"],
      github_username: user["login"],
      twitter_username: user["twitter_username"],
      onboarding: 'welcome'
    }

    profile_params = %{
      company: user["company"],
      location: user["location"],
      description: user["bio"]
    }

    # FIXME: create a unique key (provider, provider_uid) => needs heroku provider_uid
    # TODO: if primary email is verified, mark it as verified as well in Azimutt
    Accounts.get_user_by_provider(provider, provider_uid)
    |> Result.flat_map_error(fn _ -> Accounts.get_user_by_email(user_params[:email]) end)
    |> Result.tap(fn user -> user |> Accounts.set_user_provider(user_params, now) end)
    |> Result.flat_map_error(fn _ ->
      Accounts.register_github_user(user_params, profile_params, UserAuth.get_attribution(conn), now)
      |> Result.tap(fn user -> Accounts.send_email_confirmation(user, &Routes.user_confirmation_url(conn, :confirm, &1)) end)
    end)
    |> Result.map(fn user -> UserAuth.login_user_and_redirect(conn, user, provider) end)
    |> Result.or_else(callback(conn, %{}))
  end

  def callback(conn, _params) do
    conn |> put_flash(:error, "Authentication failed") |> redirect(to: Routes.website_path(conn, :index))
  end

  defp to_map(%Ueberauth.Auth{} = data) do
    data.extra.raw_info.user
  end
end
