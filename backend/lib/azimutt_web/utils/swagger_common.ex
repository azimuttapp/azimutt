defmodule AzimuttWeb.Utils.SwaggerCommon do
  @moduledoc "Common parameter declarations for phoenix swagger"
  alias PhoenixSwagger.Path.PathObject
  import PhoenixSwagger.Path

  def authorization(%PathObject{} = path) do
    path |> parameter("auth-token", :header, :string, "Your auth token, create it from user settings")
  end

  def project_path, do: "/organizations/{organization_id}/projects/{project_id}"

  def project_params(%PathObject{} = path) do
    path
    |> parameter("organization_id", :path, :string, "UUID of your organization", format: "uuid", required: true)
    |> parameter("project_id", :path, :string, "UUID of your project", format: "uuid", required: true)
  end
end
