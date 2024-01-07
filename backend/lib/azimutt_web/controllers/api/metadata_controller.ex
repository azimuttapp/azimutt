defmodule AzimuttWeb.Api.MetadataController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.JsonSchema
  alias AzimuttWeb.Utils.ProjectSchema
  alias AzimuttWeb.Utils.SwaggerCommon
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :index do
    tag("Metadata")
    summary("Get project metadata")
    description("Get all metadata for the project, ie all notes and tags for all tables and columns.")
    produces("application/json")
    get("#{SwaggerCommon.project_path()}/metadata")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    response(200, "OK", Schema.ref(:ProjectMetadata))
    response(400, "Client Error")
  end

  def index(conn, %{"organization_id" => _organization_id, "project_id" => project_id}) do
    with {:ok, %Project{} = project} <- Projects.get_project(project_id, conn.assigns.current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("index.json", metadata: content["metadata"] || %{})
  end

  swagger_path :update do
    tag("Metadata")
    summary("Update project metadata")
    description("Set the whole project metadata at once. Fetch it, update it then update it. Beware to not override changes made by others.")
    produces("application/json")
    put("#{SwaggerCommon.project_path()}/metadata")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      payload(:body, :object, "Project Metadata", required: true, schema: Schema.ref(:ProjectMetadata))
    end

    response(200, "OK", Schema.ref(:ProjectMetadata))
    response(400, "Client Error")
  end

  def update(conn, %{"organization_id" => _organization_id, "project_id" => project_id}) do
    with {:ok, body} <- conn.body_params |> JsonSchema.validate(ProjectSchema.metadata()) |> Result.zip_error_left(:bad_request),
         {:ok, updated} <-
           Projects.update_project_content(project_id, conn.assigns.current_user, DateTime.utc_now(), fn project ->
             project |> Map.put("metadata", body)
           end),
         do: conn |> render("index.json", metadata: updated["metadata"] || %{})
  end

  swagger_path :table do
    tag("Metadata")
    summary("Get table metadata")
    description("Get all metadata for the table, notes and tags. You can include columns metadata too with the `expand` query param.")
    produces("application/json")
    get("#{SwaggerCommon.project_path()}/tables/{table_id}/metadata")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      table_id(:path, :string, "Id of the table (ex: public.users)", required: true)
      expand(:query, :array, "Expand columns metadata", collectionFormat: "csv", items: %{type: "string", enum: ["columns"]})
    end

    response(200, "OK", Schema.ref(:TableMetadata))
    response(400, "Client Error")
  end

  def table(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id} = params) do
    with {:ok, %Project{} = project} <- Projects.get_project(project_id, conn.assigns.current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("table.json", metadata: content["metadata"][table_id] || %{}, show_columns: params["expand"] == "columns")
  end

  swagger_path :table_update do
    tag("Metadata")
    summary("Update table metadata")
    description("Set table metadata. If you include columns, they will be replaced, otherwise they will stay the same.")
    produces("application/json")
    put("#{SwaggerCommon.project_path()}/tables/{table_id}/metadata")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      table_id(:path, :string, "Id of the table (ex: public.users)", required: true)
      payload(:body, :object, "Table Metadata", required: true, schema: Schema.ref(:TableMetadata))
    end

    response(200, "OK", Schema.ref(:TableMetadata))
    response(400, "Client Error")
  end

  def table_update(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id}) do
    with {:ok, body} <- conn.body_params |> JsonSchema.validate(ProjectSchema.table_meta()) |> Result.zip_error_left(:bad_request),
         {:ok, updated} <-
           Projects.update_project_content(project_id, conn.assigns.current_user, DateTime.utc_now(), fn project ->
             project
             |> Mapx.update_in(["metadata", table_id], fn table ->
               cond do
                 body["columns"] -> body
                 table["columns"] -> body |> Map.put("columns", table["columns"])
                 true -> body
               end
             end)
           end),
         do: conn |> render("table.json", metadata: updated["metadata"][table_id] || %{}, show_columns: not is_nil(body["columns"]))
  end

  swagger_path :column do
    tag("Metadata")
    summary("Get column metadata")
    description("Get all metadata for the column, notes and tags. For nested columns, use the column path (ex: details:address:street).")
    produces("application/json")
    get("#{SwaggerCommon.project_path()}/tables/{table_id}/columns/{column_path}/metadata")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      table_id(:path, :string, "Id of the table (ex: public.users)", required: true)
      column_path(:path, :string, "Path of the column (ex: id, name or details:location)", required: true)
    end

    response(200, "OK", Schema.ref(:ColumnMetadata))
    response(400, "Client Error")
  end

  def column(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id, "column_path" => column_path}) do
    with {:ok, %Project{} = project} <- Projects.get_project(project_id, conn.assigns.current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("column.json", metadata: content["metadata"][table_id]["columns"][column_path] || %{})
  end

  swagger_path :column_update do
    tag("Metadata")
    summary("Update column metadata")
    description("Set column metadata. For nested columns, use the column path (ex: details:address:street).")
    produces("application/json")
    put("#{SwaggerCommon.project_path()}/tables/{table_id}/columns/{column_path}/metadata")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      table_id(:path, :string, "Id of the table (ex: public.users)", required: true)
      column_path(:path, :string, "Path of the column (ex: id, name or details:location)", required: true)
      payload(:body, :object, "Column Metadata", required: true, schema: Schema.ref(:ColumnMetadata))
    end

    response(200, "OK", Schema.ref(:ColumnMetadata))
    response(400, "Client Error")
  end

  def column_update(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "table_id" => table_id, "column_path" => column_path}) do
    with {:ok, body} <- conn.body_params |> JsonSchema.validate(ProjectSchema.column_meta()) |> Result.zip_error_left(:bad_request),
         {:ok, updated} <-
           Projects.update_project_content(project_id, conn.assigns.current_user, DateTime.utc_now(), fn project ->
             project |> Mapx.put_in(["metadata", table_id, "columns", column_path], body)
           end),
         do: conn |> render("column.json", metadata: updated["metadata"][table_id]["columns"][column_path] || %{})
  end

  def swagger_definitions do
    %{
      ProjectMetadata:
        swagger_schema do
          title("ProjectMetadata")
          description("All Metadata of the project")
          type(:object)
          additional_properties(Schema.ref(:TableMetadata))

          example(%{
            "public.users": %{
              notes: "Table notes",
              tags: ["table-tag"],
              columns: %{
                id: %{
                  notes: "Column notes",
                  tags: ["column-tag"]
                },
                "settings:theme": %{
                  notes: "Nested column notes",
                  tags: ["nested-column-tag"]
                }
              }
            },
            ".test": %{
              notes: "Table with empty schema"
            }
          })
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

          example(%{
            notes: "Table notes",
            tags: ["table-tag"],
            columns: %{
              id: %{
                notes: "Column notes",
                tags: ["column-tag"]
              },
              "settings:theme": %{
                notes: "Nested column notes",
                tags: ["nested-column-tag"]
              }
            }
          })
        end,
      ColumnMetadata:
        swagger_schema do
          title("ColumnMetadata")
          description("The Metadata used to document columns")

          properties do
            notes(:string, "Markdown text to document the column", example: "*Column* notes")
            tags(:array, "Tags to categorize the column", items: %{type: :string}, example: ["column-tag"])
          end

          example(%{
            notes: "Column notes",
            tags: ["column-tag"]
          })
        end
    }
  end
end
