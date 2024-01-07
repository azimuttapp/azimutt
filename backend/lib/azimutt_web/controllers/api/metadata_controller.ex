defmodule AzimuttWeb.Api.MetadataController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.CtxParams
  alias AzimuttWeb.Utils.ProjectSchema
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :index do
    tag("Metadata")
    summary("Get project metadata")
    description("Get all metadata for the project, ie all notes and tags for all tables and columns.")
    produces("application/json")
    get("/organizations/{organization_id}/projects/{project_id}/metadata")

    parameters do
      organization_id(:path, :string, "Organization Id", format: "uuid", required: true)
      project_id(:path, :string, "Project Id", required: true)
    end

    response(200, "OK", Schema.ref(:ProjectMetadata))
    response(400, "Client Error")
  end

  def index(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("index.json", metadata: content["metadata"], ctx: ctx)
  end

  swagger_path :update do
    tag("Metadata")
    summary("Update project metadata")
    description("Set the whole project metadata at once. Fetch it, update it then update it. Beware to not override changes made by others.")
    produces("application/json")
    put("/organizations/{organization_id}/projects/{project_id}/metadata")

    parameters do
      organization_id(:path, :string, "Organization Id", required: true)
      project_id(:path, :string, "Project Id", required: true)
      payload(:body, :object, "Project Metadata", required: true, schema: Schema.ref(:ProjectMetadata))
    end

    response(200, "OK", Schema.ref(:ProjectMetadata))
    response(400, "Client Error")
  end

  def update(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    now = DateTime.utc_now()
    ctx = CtxParams.from_params(params)
    current_user = conn.assigns.current_user

    update_schema = ProjectSchema.project_meta()

    with {:ok, body} <- validate_json_schema(update_schema, conn.body_params) |> Result.zip_error_left(:bad_request),
         {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project),
         {:ok, json} <- Jason.decode(content),
         json_updated = json |> Map.put("metadata", body),
         {:ok, content_updated} <- Jason.encode(json_updated),
         {:ok, %Project{} = _project_updated} <- Projects.update_project_file(project, content_updated, current_user, now),
         do: conn |> render("index.json", metadata: json_updated["metadata"] || %{}, ctx: ctx)
  end

  swagger_path :table do
    tag("Metadata")
    summary("Get table metadata")
    description("")
    produces("application/json")
    get("/organizations/{organization_id}/projects/{project_id}/tables/{table_id}/metadata")

    parameters do
      organization_id(:path, :string, "Organization Id", required: true)
      project_id(:path, :string, "Project Id", required: true)
      table_id(:path, :string, "Table Id", required: true)
      expand(:query, :array, "Expand columns metadata", collectionFormat: "csv", items: %{type: "string", enum: ["columns"]})
    end

    response(200, "OK", Schema.ref(:TableMetadata))
    response(400, "Client Error")
  end

  def table(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("table.json", metadata: content["metadata"][table_id] || %{}, ctx: ctx)
  end

  swagger_path :table_update do
    tag("Metadata")
    summary("Update table metadata")
    description("If you include `columns` they will be replaced, otherwise they will stay the same.")
    produces("application/json")
    put("/organizations/{organization_id}/projects/{project_id}/tables/{table_id}/metadata")

    parameters do
      organization_id(:path, :string, "Organization Id", required: true)
      project_id(:path, :string, "Project Id", required: true)
      table_id(:path, :string, "Table Id", required: true)
      payload(:body, :object, "Table Metadata", required: true, schema: Schema.ref(:TableMetadata))
    end

    response(200, "OK", Schema.ref(:TableMetadata))
    response(400, "Client Error")
  end

  def table_update(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id} = params) do
    now = DateTime.utc_now()
    ctx = CtxParams.from_params(params)
    current_user = conn.assigns.current_user

    update_schema = ProjectSchema.table_meta()

    with {:ok, body} <- validate_json_schema(update_schema, conn.body_params) |> Result.zip_error_left(:bad_request),
         {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project),
         {:ok, json} <- Jason.decode(content),
         json_updated =
           json
           |> Mapx.update_in(["metadata", table_id], fn v ->
             if body["columns"] do
               body
             else
               if v["columns"] do
                 body |> Map.merge(%{"columns" => v["columns"]})
               else
                 body
               end
             end
           end),
         {:ok, content_updated} <- Jason.encode(json_updated),
         {:ok, %Project{} = _project_updated} <- Projects.update_project_file(project, content_updated, current_user, now),
         do: conn |> render("table.json", metadata: json_updated["metadata"][table_id] || %{}, ctx: ctx)
  end

  swagger_path :column do
    tag("Metadata")
    summary("Get column metadata")
    description("Use column path (ie: details:address:street) for nested columns.")
    produces("application/json")
    get("/organizations/{organization_id}/projects/{project_id}/tables/{table_id}/columns/{column_path}/metadata")

    parameters do
      organization_id(:path, :string, "Organization Id", required: true)
      project_id(:path, :string, "Project Id", required: true)
      table_id(:path, :string, "Table Id", required: true)
      column_path(:path, :string, "Column Path", required: true)
    end

    response(200, "OK", Schema.ref(:ColumnMetadata))
    response(400, "Client Error")
  end

  def column(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id, "column_path" => column_path} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("column.json", metadata: content["metadata"][table_id]["columns"][column_path] || %{}, ctx: ctx)
  end

  swagger_path :column_update do
    tag("Metadata")
    summary("Update column metadata")
    description("Use column path (ie: details:address:street) for nested columns.")
    produces("application/json")
    put("/organizations/{organization_id}/projects/{project_id}/tables/{table_id}/columns/{column_path}/metadata")

    parameters do
      organization_id(:path, :string, "Organization Id", required: true)
      project_id(:path, :string, "Project Id", required: true)
      table_id(:path, :string, "Table Id", required: true)
      column_path(:path, :string, "Column Path", required: true)
      payload(:body, :object, "Column Metadata", required: true, schema: Schema.ref(:ColumnMetadata))
    end

    response(200, "OK", Schema.ref(:ColumnMetadata))
    response(400, "Client Error")
  end

  def column_update(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id, "column_path" => column_path} = params) do
    now = DateTime.utc_now()
    ctx = CtxParams.from_params(params)
    current_user = conn.assigns.current_user

    update_schema = ProjectSchema.column_meta()

    with {:ok, body} <- validate_json_schema(update_schema, conn.body_params) |> Result.zip_error_left(:bad_request),
         {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project),
         {:ok, json} <- Jason.decode(content),
         json_updated = json |> Mapx.put_in(["metadata", table_id, "columns", column_path], body),
         {:ok, content_updated} <- Jason.encode(json_updated),
         {:ok, %Project{} = _project_updated} <- Projects.update_project_file(project, content_updated, current_user, now),
         do: conn |> render("column.json", metadata: json_updated["metadata"][table_id]["columns"][column_path] || %{}, ctx: ctx)
  end

  defp validate_json_schema(schema, json) do
    # TODO: add the string uuid format validation
    ExJsonSchema.Validator.validate(schema, json)
    |> Result.map_both(
      fn errors -> %{errors: errors |> Enum.map(fn {error, path} -> %{path: path, error: error} end)} end,
      fn _ -> json end
    )
  end

  def swagger_definitions do
    %{
      ProjectMetadata:
        swagger_schema do
          title("ProjectMetadata")
          description("The Metadata of the project")
          type(:object)
          # additionalProperties Schema.ref(:TableMetadata)
        end,
      TableMetadata:
        swagger_schema do
          title("TableMetadata")
          description("The Metadata used to document tables")

          properties do
            notes(:string, "Markdown text to document the table", example: "*Table* notes")
            tags(:array, "Tags to categorize the table", items: %{type: :string}, example: ["table-tag"])
            columns(:object, "Columns metadata", additionalProperties: Schema.ref(:ColumnMetadata))
          end
        end,
      ColumnMetadata:
        swagger_schema do
          title("ColumnMetadata")
          description("The Metadata used to document columns")

          properties do
            notes(:string, "Markdown text to document the column", example: "*Column* notes")
            tags(:array, "Tags to categorize the column", items: %{type: :string}, example: ["column-tag"])
          end
        end
    }
  end
end
