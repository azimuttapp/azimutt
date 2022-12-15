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

  # helper to ease heroku testing in local
  def index(conn, _params) do
    # defined as env variable (see .env), don't use env vars to make leak impossible
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

    if invalid_token || older_than_5_min do
      {:error, :forbidden}
    else
      with {:ok, resource} <- Heroku.get_resource(resource_id),
           {:ok, user} <- Accounts.get_user_by_email(email) |> Result.flat_map_error(fn _ -> Accounts.register_heroku_user(email, now) end),
           {:ok, organization} <- Heroku.add_organization_if_needed(resource, user, now),
           {:ok, _} <- Heroku.add_member_if_needed(resource, organization, user) do
        conn = conn |> UserAuth.heroku_sso(resource, user, app)
        project = Projects.list_projects(organization, user) |> List.first()

        if project do
          conn |> redirect(to: Routes.elm_path(conn, :project_show, organization.id, project.id))
        else
          conn |> redirect(to: Routes.heroku_path(conn, :show, resource.id))
        end
      end
      |> case do
        {:error, :not_found} -> {:error, :not_found}
        {:error, :deleted} -> {:error, :gone}
        {:error, :too_many_members} -> conn |> render("error_too_many_members.html", app_url: Heroku.app_addons_url(app))
        {:error, :member_limit_reached} -> conn |> render("error_member_limit_reached.html", app_url: Heroku.app_addons_url(app))
        {:error, err} -> conn |> put_flash(:error, "Authentication failed: #{err}") |> redirect(to: Routes.website_path(conn, :index))
        conn -> conn
      end
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    %{resource: resource, app: app} = conn.assigns.heroku

    if resource.id == id do
      conn
      |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
      |> put_root_layout({AzimuttWeb.LayoutView, "empty.html"})
      # Heroku color: #79589f, 20% darker: #61467f, 20% lighter: #9377b4
      |> render("show.html", resource: resource, user: current_user, app: app)
    else
      {:error, :forbidden}
    end
  end

  defp heroku_token(resource_id, timestamp, salt), do: Crypto.sha1("#{resource_id}:#{salt}:#{timestamp}")
end
