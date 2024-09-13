# Clever Cloud addon: https://www.clever-cloud.com/doc/extend/add-ons-api/#sso
defmodule AzimuttWeb.CleverCloudController do
  use AzimuttWeb, :controller
  require Logger
  alias Azimutt.Accounts
  alias Azimutt.CleverCloud
  alias Azimutt.Projects
  alias Azimutt.Utils.Crypto
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  # helper to ease clever cloud testing in local
  def index(conn, _params) do
    # defined as env variable (see .env), don't use env vars to make leak impossible
    clever_cloud = %{
      addon_id: "azimutt-dev",
      password: "pass",
      sso_salt: "salt"
    }

    resources = CleverCloud.all_resources()
    conn |> render("index.html", clever_cloud: clever_cloud, resources: resources)
  end

  # https://www.clever-cloud.com/doc/extend/add-ons-api/#sso
  # TODO: how to get user_id in SSO? Get it from the resource? What happen if several users from Clever Cloud???
  def login(conn, %{"id" => resource_id, "token" => token, "timestamp" => timestamp, "email" => email} = params) do
    Logger.info("CleverCloudController.login: #{inspect(params)}")
    now = DateTime.utc_now()
    now_ts = System.os_time(:second)
    salt = Azimutt.config(:clever_cloud_sso_salt)
    older_than_15_min = String.to_integer(timestamp) < now_ts - 15 * 60
    expected_token = build_token(resource_id, salt, timestamp)
    invalid_token = !Plug.Crypto.secure_compare(expected_token, token)

    user_params = %{
      name: email |> String.split("@") |> hd(),
      email: email,
      avatar: "https://www.gravatar.com/avatar/#{Crypto.md5(email)}?s=150&d=robohash",
      provider: "clever_cloud",
      provider_uid: email,
      provider_data: %{resource_id: resource_id, nav_data: params["nav-data"]}
    }

    if invalid_token || older_than_15_min do
      {:error, :forbidden}
    else
      with {:ok, resource} <- CleverCloud.get_resource(resource_id),
           {:ok, user} <-
             Accounts.get_user_by_email(email)
             |> Result.flat_map_error(fn _ -> Accounts.register_clever_cloud_user(user_params, UserAuth.get_attribution(conn), now) end),
           {:ok, resource} <- CleverCloud.set_organization_if_needed(resource, user, now),
           {:ok, _} <- CleverCloud.add_member_if_needed(resource, user) do
        conn = conn |> UserAuth.clever_cloud_sso(resource, user)
        project = Projects.list_projects(resource.organization, user) |> Enum.sort_by(& &1.updated_at, {:desc, DateTime}) |> List.first()

        if project do
          conn |> redirect(to: Routes.elm_path(conn, :project_show, resource.organization.id, project.id))
        else
          conn |> redirect(to: Routes.clever_cloud_path(conn, :show, resource.id))
        end
      end
      |> case do
        {:error, :not_found} ->
          {:error, :not_found}

        {:error, :deleted} ->
          {:error, :gone}

        {:error, :too_many_members, resource} ->
          conn
          |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
          |> put_root_layout({AzimuttWeb.LayoutView, "root_hfull.html"})
          |> render("error_too_many_members.html", resource: resource)

        {:error, :member_limit_reached, resource} ->
          conn
          |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
          |> put_root_layout({AzimuttWeb.LayoutView, "root_hfull.html"})
          |> render("error_member_limit_reached.html", resource: resource)

        {:error, err} ->
          conn |> put_flash(:error, "Authentication failed: #{Stringx.inspect(err)}") |> redirect(to: Routes.website_path(conn, :index))

        conn ->
          conn
      end
    end
  end

  def show(conn, %{"resource_id" => resource_id}) do
    current_user = conn.assigns.current_user
    resource = conn.assigns.clever_cloud

    if resource.id == resource_id do
      conn
      |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
      |> put_root_layout({AzimuttWeb.LayoutView, "empty.html"})
      |> render("show.html",
        resource: resource,
        user: current_user,
        color: "#d74d4e",
        dark_20: "#bf2b2c",
        dark_50: "#771b1b",
        light_20: "#df7171"
      )
    else
      {:error, :forbidden}
    end
  end

  defp build_token(resource_id, salt, timestamp), do: Crypto.sha1("#{resource_id}:#{salt}:#{timestamp}")
end
