defmodule AzimuttWeb.Api.SourceController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.CtxParams
  action_fallback AzimuttWeb.Api.FallbackController

  # TODO: add swagger doc
  # TODO: remove origin fields in sources

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

  def update(conn, %{"organization_id" => _organization_id, "project_id" => _project_id, "source_id" => _source_id} = _params) do
    # FIXME, forbid to edit AmlEditor sources
    conn |> send_resp(:not_found, "WIP")
  end

  def create(conn, %{"organization_id" => _organization_id, "project_id" => _project_id} = _params) do
    # FIXME
    conn |> send_resp(:not_found, "WIP")
  end

  def delete(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "source_id" => source_id} = params) do
    now = DateTime.utc_now()
    ctx = CtxParams.from_params(params)
    current_user = conn.assigns.current_user

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project),
         {:ok, json} <- Jason.decode(content),
         {:ok, source} <- json["sources"] |> Enum.find(fn s -> s["id"] == source_id end) |> Result.from_nillable(),
         json_updated = json |> Map.put("sources", json["sources"] |> Enum.reject(fn s -> s["id"] == source_id end)),
         {:ok, content_updated} <- Jason.encode(json_updated),
         {:ok, %Project{} = _project_updated} <- Projects.update_project_file(project, content_updated, current_user, now),
         do: conn |> render("show.json", source: source, ctx: ctx)
  end
end
