defmodule AzimuttWeb.Api.SourceController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.CtxParams
  action_fallback AzimuttWeb.Api.FallbackController

  def index(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("index.json", sources: content["sources"], ctx: ctx)
  end

  def show(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "source_id" => source_id} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         {:ok, source} <- content["sources"] |> Enum.find(fn s -> s["id"] == source_id end) |> Result.from_nillable(),
         do: conn |> render("show.json", source: source, ctx: ctx)
  end

  def update(conn, %{"organization_organization_id" => _organization_id, "project_id" => _project_id, "source_id" => _source_id} = _params) do
    # FIXME
    conn |> send_resp(:not_found, "WIP")
  end

  def create(conn, %{"organization_organization_id" => _organization_id, "project_id" => _project_id} = _params) do
    conn |> send_resp(:not_found, "WIP")
  end

  def delete(conn, %{"organization_organization_id" => _organization_id, "project_id" => _project_id, "source_id" => _source_id}) do
    conn |> send_resp(:not_found, "WIP")
  end
end
