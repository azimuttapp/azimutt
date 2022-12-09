# handle specific Heroku needs for https://elements.heroku.com/addons#data-store-utilities
# see https://devcenter.heroku.com/categories/building-add-ons
# see https://devcenter.heroku.com/articles/building-an-add-on
# see https://devcenter.heroku.com/articles/add-on-single-sign-on
defmodule AzimuttWeb.HerokuController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Heroku
  alias Azimutt.Utils.Crypto
  alias Azimutt.Utils.Result
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  # ease heroku testing in dev
  def index(conn, _params) do
    # defined as env variable (see .env)
    heroku = %{
      addon_id: "azimutt-dev",
      password: "pass",
      sso_salt: "salt"
    }

    resources = Heroku.all_resources()
    conn |> render("index.html", heroku: heroku, resources: resources)
  end

  # https://devcenter.heroku.com/articles/add-on-single-sign-on
  # https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request-example-request
  def login(conn, %{"resource_id" => heroku_id, "timestamp" => timestamp, "resource_token" => token, "email" => email, "app" => app}) do
    now = DateTime.utc_now()
    now_ts = System.os_time(:second)
    salt = Azimutt.config(:heroku_sso_salt)
    older_than_5_min = String.to_integer(timestamp) < now_ts - 5 * 60
    expected_token = heroku_token(heroku_id, timestamp, salt)
    invalid_token = !Plug.Crypto.secure_compare(expected_token, token)

    if older_than_5_min || invalid_token do
      {:error, :forbidden}
    else
      case Heroku.get_resource(heroku_id) do
        {:ok, resource} ->
          user_params = %{
            name: email |> String.split("@") |> hd(),
            email: email,
            avatar: "https://www.gravatar.com/avatar/#{Crypto.md5(email)}?s=150&d=robohash",
            provider: "heroku"
          }

          Accounts.get_user_by_email(user_params.email)
          |> Result.flat_map_error(fn _ -> Accounts.register_heroku_user(user_params, now) end)
          |> Result.tap(fn user -> Heroku.set_resource_member(resource, user) end)
          |> Result.map(fn user -> conn |> UserAuth.heroku_sso(resource, user, app) end)
          |> Result.or_else(conn |> put_flash(:error, "Authentication failed") |> redirect(to: Routes.website_path(conn, :index)))

        {:error, :not_found} ->
          conn |> send_resp(:not_found, "")

        {:error, :deleted} ->
          conn |> send_resp(:gone, "")
      end
    end
  end

  def show(conn, %{"heroku_id" => heroku_id} = params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku show resource")
    current_user = conn.assigns.current_user
    %{resource: resource, app: app} = conn.assigns.heroku

    if resource.heroku_id == heroku_id do
      organization = Accounts.get_user_personal_organization(current_user)
      conn |> render("show.html", resource: resource, user: current_user, organization: organization, app: app)
    else
      {:error, :forbidden}
    end
  end

  defp heroku_token(heroku_id, timestamp, salt), do: Crypto.sha1("#{heroku_id}:#{salt}:#{timestamp}")
  # defp heroku_dashboard(user), do: "https://dashboard.heroku.com/apps/#{user.app}"
end
