defmodule AzimuttWeb.Api.SourceController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.CtxParams
  alias AzimuttWeb.Utils.ProjectSchema
  action_fallback AzimuttWeb.Api.FallbackController

  # TODO: add swagger doc
  # TODO: remove origin fields in sources (Elm & JS)

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

  def create(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    now = DateTime.utc_now()
    ctx = CtxParams.from_params(params)
    current_user = conn.assigns.current_user

    create_schema = %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["name", "kind", "tables", "relations"],
      "properties" => %{
        "name" => %{"type" => "string"},
        "kind" => ProjectSchema.source_kind(),
        "tables" => %{"type" => "array", "items" => ProjectSchema.table()},
        "relations" => %{"type" => "array", "items" => ProjectSchema.relation()},
        "types" => %{"type" => "array", "items" => ProjectSchema.type()},
        "enabled" => %{"type" => "boolean"}
      },
      "definitions" => %{"column" => ProjectSchema.column()}
    }

    with {:ok, body} <- validate_json_schema(create_schema, conn.body_params) |> Result.zip_error_left(:bad_request),
         {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project),
         {:ok, json} <- Jason.decode(content),
         :ok <- if(body["kind"]["kind"] == "AmlEditor", do: {:error, {:forbidden, "AML sources can't be created via API."}}, else: :ok),
         source = create_source(body, now),
         json_updated = json |> Map.put("sources", json["sources"] ++ [source]),
         {:ok, content_updated} <- Jason.encode(json_updated),
         {:ok, %Project{} = _project_updated} <- Projects.update_project_file(project, content_updated, current_user, now),
         do: conn |> render("show.json", source: source, ctx: ctx)
  end

  def update(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "source_id" => source_id} = params) do
    now = DateTime.utc_now()
    ctx = CtxParams.from_params(params)
    current_user = conn.assigns.current_user

    update_schema = %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["tables", "relations"],
      "properties" => %{
        "tables" => %{"type" => "array", "items" => ProjectSchema.table()},
        "relations" => %{"type" => "array", "items" => ProjectSchema.relation()},
        "types" => %{"type" => "array", "items" => ProjectSchema.type()}
      },
      "definitions" => %{"column" => ProjectSchema.column()}
    }

    with {:ok, body} <- validate_json_schema(update_schema, conn.body_params) |> Result.zip_error_left(:bad_request),
         {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project),
         {:ok, json} <- Jason.decode(content),
         {:ok, source} <- json["sources"] |> Enum.find(fn s -> s["id"] == source_id end) |> Result.from_nillable(),
         :ok <- if(source["kind"]["kind"] == "AmlEditor", do: {:error, {:forbidden, "AML sources can't be updated via API."}}, else: :ok),
         json_updated = json |> Map.put("sources", json["sources"] |> Enum.map(fn s -> if(s["id"] == source_id, do: update_source(s, body), else: s) end)),
         {:ok, content_updated} <- Jason.encode(json_updated),
         {:ok, %Project{} = _project_updated} <- Projects.update_project_file(project, content_updated, current_user, now),
         do: conn |> render("show.json", source: source, ctx: ctx)
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

  defp create_source(params, now) do
    params
    |> Map.put("id", Ecto.UUID.generate())
    |> Map.put("content", [])
    |> Map.put("createdAt", DateTime.to_unix(now, :millisecond))
    |> Map.put("updatedAt", DateTime.to_unix(now, :millisecond))
  end

  defp update_source(source, params) do
    source
    |> Map.put("tables", params["tables"])
    |> Map.put("relations", params["relations"])
    |> Mapx.put_no_nil("types", params["types"])
  end

  defp validate_json_schema(schema, json) do
    # TODO: add the string uuid format validation
    ExJsonSchema.Validator.validate(schema, json)
    |> Result.map_both(
      fn errors -> %{errors: errors |> Enum.map(fn {error, path} -> %{path: path, error: error} end)} end,
      fn _ -> json end
    )
  end
end
