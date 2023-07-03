# Clever Cloud addon: https://www.clever-cloud.com/doc/extend/add-ons-api
defmodule AzimuttWeb.Api.CleverCloudController do
  use AzimuttWeb, :controller
  require Logger
  alias Azimutt.CleverCloud
  alias Azimutt.Utils.Stringx
  action_fallback AzimuttWeb.Api.FallbackController

  # https://www.clever-cloud.com/doc/extend/add-ons-api/#provisioning
  def create(conn, params) do
    Logger.info("Api.CleverCloudController.create(#{Stringx.inspect(params)})")

    case CleverCloud.create_resource(params) do
      {:ok, resource} -> conn |> render("show.json", resource: resource, message: "Your Azimutt add-on is now provisioned.")
      {:error, _err} -> conn |> send_resp(:unprocessable_entity, "")
    end
  end

  # https://www.clever-cloud.com/doc/extend/add-ons-api/#plan-change
  def update(conn, %{"resource_id" => resource_id, "plan" => plan} = params) do
    Logger.info("Api.CleverCloudController.update(#{Stringx.inspect(params)})")
    now = DateTime.utc_now()

    case CleverCloud.get_resource(resource_id) do
      {:ok, resource} ->
        case CleverCloud.update_resource_plan(resource, %{plan: plan}, now) do
          {:ok, _} -> conn |> render("show.json", resource: resource, message: "Azimutt plan changed from #{resource.plan} to #{plan}.")
          {:error, _err} -> conn |> send_resp(:unprocessable_entity, "")
        end

      {:error, :not_found} ->
        conn |> send_resp(:not_found, "")

      {:error, :deleted} ->
        conn |> send_resp(:gone, "")
    end
  end

  # https://www.clever-cloud.com/doc/extend/add-ons-api/#deprovisioning
  def delete(conn, %{"resource_id" => resource_id} = params) do
    Logger.info("Api.CleverCloudController.delete(#{Stringx.inspect(params)})")
    now = DateTime.utc_now()

    case CleverCloud.get_resource(resource_id) do
      {:ok, resource} ->
        case CleverCloud.delete_resource(resource, now) do
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
