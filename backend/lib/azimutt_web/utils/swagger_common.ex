defmodule AzimuttWeb.Utils.SwaggerCommon do
  @moduledoc "Common parameter declarations for phoenix swagger"
  import PhoenixSwagger.Path
  alias AzimuttWeb.Utils.SwaggerCommon
  alias PhoenixSwagger.Path.PathObject

  def authorization(%PathObject{} = path),
    do: path |> parameter("auth-token", :header, :string, "Your auth token, needed if you don't have the auth cookie, create it from user settings")

  def organization_path, do: "/organizations/{organization_id}"

  def organization_params(%PathObject{} = path),
    do: path |> parameter("organization_id", :path, :string, "UUID of your organization", format: "uuid", required: true)

  def project_path, do: "#{SwaggerCommon.organization_path()}/projects/{project_id}"

  def project_params(%PathObject{} = path),
    do: path |> SwaggerCommon.organization_params() |> parameter("project_id", :path, :string, "UUID of your project", format: "uuid", required: true)
end
