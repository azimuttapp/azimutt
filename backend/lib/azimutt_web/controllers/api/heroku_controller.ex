# Heroku partner portal: https://addons-next.heroku.com
# handle specific Heroku needs for https://elements.heroku.com/addons#data-store-utilities
# see https://devcenter.heroku.com/categories/building-add-ons
# see https://devcenter.heroku.com/articles/building-an-add-on
# see https://devcenter.heroku.com/articles/add-on-single-sign-on
defmodule AzimuttWeb.Api.HerokuController do
  use AzimuttWeb, :controller
  alias Azimutt.Heroku
  action_fallback AzimuttWeb.Api.FallbackController

  # https://devcenter.heroku.com/articles/add-on-partner-api-reference#add-on-provision
  # https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request-example-request
  # this endpoint MUST be idempotent (one resource per uuid), return 410 if deleted and 422 on error
  def create(conn, %{"uuid" => resource_id} = params) do
    case Heroku.get_resource(resource_id) do
      {:ok, resource} ->
        conn |> render("show.json", resource: resource, message: "This resource was already created.")

      {:error, :not_found} ->
        case Heroku.create_resource(%{
               id: resource_id,
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

      {:error, :deleted} ->
        conn |> send_resp(:gone, "")
    end
  end

  # https://devcenter.heroku.com/articles/add-on-partner-api-reference#add-on-plan-change
  # https://devcenter.heroku.com/articles/building-an-add-on#the-plan-change-request-upgrade-downgrade
  def update(conn, %{"resource_id" => resource_id, "plan" => plan}) do
    now = DateTime.utc_now()

    case Heroku.get_resource(resource_id) do
      {:ok, resource} ->
        case Heroku.update_resource_plan(resource, %{plan: plan}, now) do
          {:ok, _} -> conn |> render("show.json", resource: resource, message: "Plan changed from #{resource.plan} to #{plan}.")
          {:error, _err} -> conn |> send_resp(:unprocessable_entity, "")
        end

      {:error, :not_found} ->
        conn |> send_resp(:not_found, "")

      {:error, :deleted} ->
        conn |> send_resp(:gone, "")
    end
  end

  # https://devcenter.heroku.com/articles/add-on-partner-api-reference#add-on-deprovision
  # https://devcenter.heroku.com/articles/building-an-add-on#the-deprovisioning-request-example-request
  def delete(conn, %{"resource_id" => resource_id}) do
    now = DateTime.utc_now()

    case Heroku.get_resource(resource_id) do
      {:ok, resource} ->
        case Heroku.delete_resource(resource, now) do
          {:ok, _resource} -> conn |> send_resp(:no_content, "")
          {:error, _err} -> conn |> send_resp(:unprocessable_entity, "")
        end

      {:error, :not_found} ->
        conn |> send_resp(:not_found, "")

      {:error, :deleted} ->
        conn |> send_resp(:gone, "")
    end
  end
end
