# handle specific Heroku needs for https://elements.heroku.com/addons#data-store-utilities
# see https://devcenter.heroku.com/categories/building-add-ons
# see https://devcenter.heroku.com/articles/building-an-add-on
# see https://devcenter.heroku.com/articles/add-on-single-sign-on
defmodule AzimuttWeb.Api.HerokuController do
  use AzimuttWeb, :controller
  alias Azimutt.Heroku
  alias Azimutt.Utils.Crypto
  action_fallback AzimuttWeb.Api.FallbackController

  # SSO from Heroku: https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request-example-request
  def login(conn, params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku login")
    now = System.os_time(:second)
    timestamp = String.to_integer(params["timestamp"])
    older_than_5_min = timestamp < now - 5 * 60
    salt = Application.get_env(:heroku, :sso_salt)
    token = Crypto.sha1("#{params["resource_id"]}:#{salt}:#{params["timestamp"]}")
    has_valid_token = Plug.Crypto.secure_compare(token, params["resource_token"])

    cond do
      older_than_5_min -> conn |> send_resp(:forbidden, "")
      # FIXME: create user session for the heroku resource
      has_valid_token -> conn |> redirect(to: Routes.user_dashboard_path(conn, :index))
      true -> conn |> send_resp(:forbidden, "")
    end
  end

  # https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request-example-request
  # https://devcenter.heroku.com/articles/add-on-partner-api-reference#add-on-provision
  # this endpoint MUST be idempotent (one resource per uuid), return 410 if deleted and 422 on error
  def create(conn, %{"uuid" => heroku_id} = params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku create resource")

    case Heroku.get_resource(heroku_id) do
      {:ok, resource} ->
        if resource.deleted_at do
          conn |> send_resp(:gone, "")
        else
          conn |> render("show.json", resource: resource, message: "This resource was already created.")
        end

      {:error, :not_found} ->
        case Heroku.create_resource(%{
               heroku_id: params["uuid"],
               name: params["name"],
               plan: params["plan"],
               region: params["region"],
               options: params["options"],
               callback: params["callback_url"],
               oauth_code: params["oauth_grant"]["code"],
               oauth_type: params["oauth_grant"]["type"],
               oauth_expire: params["oauth_grant"]["expires_at"]
             }) do
          {:ok, resource} -> conn |> render("show.json", resource: resource, message: "Your add-on is now provisioned.")
          {:error, _err} -> conn |> send_resp(:unprocessable_entity, "")
        end
    end
  end

  # https://devcenter.heroku.com/articles/building-an-add-on#the-plan-change-request-upgrade-downgrade
  def update(conn, %{"heroku_id" => heroku_id} = params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku update resource")
    now = DateTime.utc_now()
    plan = params["plan"]

    case Heroku.get_resource(heroku_id) do
      {:ok, resource} ->
        if resource.deleted_at do
          conn |> send_resp(:gone, "")
        else
          case Heroku.update_resource(resource, %{plan: plan}, now) do
            {:ok, _resource} -> conn |> render("show.json", resource: resource, message: "Plan updated to #{plan}.")
            {:error, _err} -> conn |> send_resp(:unprocessable_entity, "")
          end
        end

      {:error, :not_found} ->
        conn |> send_resp(:not_found, "")
    end
  end

  # https://devcenter.heroku.com/articles/building-an-add-on#the-deprovisioning-request-example-request
  def delete(conn, %{"heroku_id" => heroku_id} = params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku delete resource")
    now = DateTime.utc_now()

    case Heroku.get_resource(heroku_id) do
      {:ok, resource} ->
        if resource.deleted_at do
          conn |> send_resp(:gone, "")
        else
          case Heroku.delete_resource(resource, now) do
            {:ok, _resource} -> conn |> send_resp(:no_content, "")
            {:error, _err} -> conn |> send_resp(:unprocessable_entity, "")
          end
        end

      {:error, :not_found} ->
        conn |> send_resp(:not_found, "")
    end
  end
end
