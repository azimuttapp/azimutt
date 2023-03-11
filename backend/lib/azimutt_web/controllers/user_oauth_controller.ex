defmodule AzimuttWeb.UserOauthController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
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

    Accounts.get_user_by_email(user_params.email)
    |> Result.flat_map_error(fn _ -> Accounts.register_github_user(user_params, UserAuth.get_attribution(conn), now) end)
    |> Result.map(fn user -> UserAuth.log_in_user(conn, user, "github") end)
    |> Result.or_else(callback(conn, %{}))
  end

  def callback(conn, _params) do
    conn |> put_flash(:error, "Authentication failed") |> redirect(to: Routes.website_path(conn, :index))
  end
end
