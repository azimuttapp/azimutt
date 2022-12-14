# handle specific Heroku needs for https://elements.heroku.com/addons#data-store-utilities
# see https://devcenter.heroku.com/categories/building-add-ons
# see https://devcenter.heroku.com/articles/building-an-add-on
# see https://devcenter.heroku.com/articles/add-on-single-sign-on
defmodule AzimuttWeb.HerokuController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Heroku
  alias Azimutt.Projects
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
  def login(conn, %{"resource_id" => resource_id, "timestamp" => timestamp, "resource_token" => token, "email" => email, "app" => app}) do
    now = DateTime.utc_now()
    now_ts = System.os_time(:second)
    salt = Azimutt.config(:heroku_sso_salt)
    older_than_5_min = String.to_integer(timestamp) < now_ts - 5 * 60
    expected_token = heroku_token(resource_id, timestamp, salt)
    invalid_token = !Plug.Crypto.secure_compare(expected_token, token)

    if older_than_5_min || invalid_token do
      {:error, :forbidden}
    else
      case Heroku.get_resource(resource_id) do
        {:ok, resource} ->
          Accounts.get_user_by_email(email)
          |> Result.flat_map_error(fn _ -> Accounts.register_heroku_user(email, now) end)
          |> Result.flat_map_with(fn user -> Heroku.add_organization_if_needed(resource, user, now) end)
          |> Result.flat_tap(fn {user, resource} -> Heroku.add_member_if_needed(resource, user) end)
          |> Result.map_with(fn {user, resource} -> conn |> UserAuth.heroku_sso(resource, user, app) end)
          |> Result.map(fn {{user, resource}, conn} ->
            project = Projects.list_projects(resource.organization, user) |> List.first()

            if project do
              conn |> redirect(to: Routes.elm_path(conn, :project_show, project.organization_id, project.id))
            else
              conn |> redirect(to: Routes.heroku_path(conn, :show, resource.id))
            end
          end)
          |> Result.or_else(conn |> put_flash(:error, "Authentication failed") |> redirect(to: Routes.website_path(conn, :index)))

        {:error, :not_found} ->
          conn |> send_resp(:not_found, "")

        {:error, :deleted} ->
          conn |> send_resp(:gone, "")
      end
    end
  end

  def show(conn, %{"id" => id} = params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku show resource")
    current_user = conn.assigns.current_user
    %{resource: resource, app: app} = conn.assigns.heroku

    if resource.id == id do
      conn |> render("show.html", resource: resource, user: current_user, app: app)
    else
      {:error, :forbidden}
    end
  end

  defp heroku_token(resource_id, timestamp, salt), do: Crypto.sha1("#{resource_id}:#{salt}:#{timestamp}")
  # defp heroku_dashboard(user), do: "https://dashboard.heroku.com/apps/#{user.app}"
end
