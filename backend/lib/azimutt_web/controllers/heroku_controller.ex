# Heroku partner portal: https://addons-next.heroku.com
# handle specific Heroku needs for https://elements.heroku.com/addons#data-store-utilities
# see https://devcenter.heroku.com/categories/building-add-ons
# see https://devcenter.heroku.com/articles/building-an-add-on
# see https://devcenter.heroku.com/articles/add-on-single-sign-on
defmodule AzimuttWeb.HerokuController do
  require Logger
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Heroku
  alias Azimutt.Projects
  alias Azimutt.Utils.Crypto
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx
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
  # TODO: should update user when github login after heroku sso? (create heroku_auth & github_auth tables?)
  def login(
        conn,
        %{"resource_id" => resource_id, "timestamp" => timestamp, "resource_token" => token, "email" => email, "app" => app} = params
      ) do
    Logger.info("HerokuController#login: #{Stringx.inspect(params)}")
    now = DateTime.utc_now()
    now_ts = System.os_time(:second)
    salt = Azimutt.config(:heroku_sso_salt)
    older_than_5_min = String.to_integer(timestamp) < now_ts - 5 * 60
    expected_token = heroku_token(resource_id, timestamp, salt)
    invalid_token = !Plug.Crypto.secure_compare(expected_token, token)
    Logger.info("HerokuController#login: #{salt} / #{now_ts}")

    if invalid_token || older_than_5_min do
      Logger.info("HerokuController#login: Invalid token (#{invalid_token} / #{older_than_5_min})")
      {:error, :forbidden}
    else
      Logger.info("HerokuController#login: Valid token")

      with {:ok, resource} <- Heroku.get_resource(resource_id),
           {:ok, user} <- Accounts.get_user_by_email(email) |> Result.flat_map_error(fn _ -> Accounts.register_heroku_user(email, now) end),
           {:ok, resource} <- Heroku.set_app_if_needed(resource, app, now),
           {:ok, resource} <- Heroku.set_organization_if_needed(resource, user, now),
           {:ok, _} <- Heroku.add_member_if_needed(resource, resource.organization, user) do
        Logger.info("HerokuController#login: SSO")
        conn = conn |> UserAuth.heroku_sso(resource, user)
        project = Projects.list_projects(resource.organization, user) |> Enum.sort_by(& &1.updated_at, {:desc, DateTime}) |> List.first()

        if project do
          conn |> redirect(to: Routes.elm_path(conn, :project_show, resource.organization.id, project.id))
        else
          conn |> redirect(to: Routes.heroku_path(conn, :show, resource.id))
        end
      end
      |> case do
        {:error, :not_found} ->
          Logger.info("HerokuController#login: not_found")
          {:error, :not_found}

        {:error, :deleted} ->
          Logger.info("HerokuController#login: gone")
          {:error, :gone}

        {:error, :too_many_members} ->
          Logger.info("HerokuController#login: too_many_members")

          conn
          |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
          |> put_root_layout({AzimuttWeb.LayoutView, "empty.html"})
          |> render("error_too_many_members.html", heroku_app: app)

        {:error, :member_limit_reached} ->
          Logger.info("HerokuController#login: member_limit_reached")

          conn
          |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
          |> put_root_layout({AzimuttWeb.LayoutView, "empty.html"})
          |> render("error_member_limit_reached.html", heroku_app: app)

        {:error, err} ->
          Logger.info(err, label: "HerokuController#login: error")
          conn |> put_flash(:error, "Authentication failed: #{Stringx.inspect(err)}") |> redirect(to: Routes.website_path(conn, :index))

        conn ->
          Logger.info("HerokuController#login: OK")
          conn
      end
    end
  end

  def show(conn, %{"id" => id} = params) do
    Logger.info("HerokuController#show: #{Stringx.inspect(params)}")
    current_user = conn.assigns.current_user
    resource = conn.assigns.heroku

    if resource.id == id do
      conn
      |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
      |> put_root_layout({AzimuttWeb.LayoutView, "empty.html"})
      # Heroku color: #79589f, 20% darker: #61467f, 20% lighter: #9377b4
      |> render("show.html", resource: resource, user: current_user)
    else
      {:error, :forbidden}
    end
  end

  defp heroku_token(resource_id, timestamp, salt), do: Crypto.sha1("#{resource_id}:#{salt}:#{timestamp}")
end
