defmodule AzimuttWeb.Api.SourceController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.CtxParams
  alias AzimuttWeb.Utils.JsonSchema
  alias AzimuttWeb.Utils.ProjectSchema
  alias AzimuttWeb.Utils.SwaggerCommon
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :index do
    tag("Sources")
    summary("List project sources")
    description("Get all the sources in a project.")
    get("#{SwaggerCommon.project_path()}/sources")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    response(200, "OK", Schema.ref(:SourceItems))
    response(400, "Client Error")
  end

  def index(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         do: conn |> render("index.json", sources: content["sources"], ctx: ctx)
  end

  swagger_path :show do
    tag("Sources")
    summary("Get a source")
    description("Get a source with its content (tables, relations and all).")
    get("#{SwaggerCommon.project_path()}/sources/{source_id}")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      source_id(:path, :string, "UUID of the source", required: true)
    end

    response(200, "OK", Schema.ref(:Source))
    response(400, "Client Error")
  end

  def show(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "source_id" => source_id} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, content} <- Projects.get_project_content(project) |> Result.flat_map(fn c -> Jason.decode(c) end),
         {:ok, source} <- content["sources"] |> Enum.find(fn s -> s["id"] == source_id end) |> Result.from_nillable(),
         do: conn |> render("show.json", source: source, ctx: ctx)
  end

  swagger_path :create do
    tag("Sources")
    summary("Create a source")
    description("Create a source with its content on a project. Can't be an `AmlEditor` source.")
    post("#{SwaggerCommon.project_path()}/sources")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      payload(:body, :object, "Source content",
        required: true,
        schema:
          Schema.new do
            properties do
              name(:string, "Source name", required: true, example: "azimutt_dev")
              kind(Schema.ref(:SourceKind), "Source kind", required: true)
              tables(:array, "Tables of the source", required: true, items: Schema.ref(:SourceTable))
              relations(:array, "Relations of the source", required: true, items: Schema.ref(:SourceRelation))
              types(:array, "Custom types of the source", items: Schema.ref(:SourceType))
              enabled(:boolean, "If the source is enabled in the project", example: true)
            end
          end
      )
    end

    response(200, "OK", Schema.ref(:Source))
    response(400, "Client Error")
  end

  def create(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    {now, current_user, ctx} = {DateTime.utc_now(), conn.assigns.current_user, CtxParams.from_params(params)}

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

    with {:ok, body} <- conn.body_params |> JsonSchema.validate(create_schema) |> Result.zip_error_left(:bad_request),
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

  swagger_path :update do
    tag("Sources")
    summary("Update a source")
    description("Update a source when it has changed. Can be a good idea to do that in your CI using the Azimutt CLI.")
    put("#{SwaggerCommon.project_path()}/sources/{source_id}")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      source_id(:path, :string, "UUID of the source", required: true)

      payload(:body, :object, "Source content",
        required: true,
        schema:
          Schema.new do
            properties do
              tables(:array, "Tables of the source", required: true, items: Schema.ref(:SourceTable))
              relations(:array, "Relations of the source", required: true, items: Schema.ref(:SourceRelation))
              types(:array, "Custom types of the source", items: Schema.ref(:SourceType))
            end
          end
      )
    end

    response(200, "OK", Schema.ref(:Source))
    response(400, "Client Error")
  end

  def update(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "source_id" => source_id} = params) do
    {now, current_user, ctx} = {DateTime.utc_now(), conn.assigns.current_user, CtxParams.from_params(params)}

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

    with {:ok, body} <- conn.body_params |> JsonSchema.validate(update_schema) |> Result.zip_error_left(:bad_request),
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

  swagger_path :delete do
    tag("Sources")
    summary("Delete a source")
    description("As you guessed ^^ It returns the deleted source.")
    PhoenixSwagger.Path.delete("#{SwaggerCommon.project_path()}/sources/{source_id}")
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    parameters do
      source_id(:path, :string, "UUID of the source", required: true)
    end

    response(200, "OK", Schema.ref(:Source))
    response(400, "Client Error")
  end

  def delete(conn, %{"organization_id" => _organization_id, "project_id" => project_id, "source_id" => source_id} = params) do
    {now, current_user, ctx} = {DateTime.utc_now(), conn.assigns.current_user, CtxParams.from_params(params)}

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

  def swagger_definitions do
    %{
      SourceKind:
        swagger_schema do
          description("The kind of a source")

          properties do
            kind(:string, "Kind of source",
              enum: ["AmlEditor", "DatabaseConnection", "SqlLocalFile", "SqlRemoteFile", "PrismaLocalFile", "PrismaRemoteFile", "JsonLocalFile", "JsonRemoteFile"],
              required: true,
              example: "DatabaseConnection"
            )

            url(:string, "Database url for DatabaseConnection kind, file url for remote kinds (SqlRemoteFile, PrismaRemoteFile & JsonRemoteFile)", example: "postgresql://postgres:postgres@localhost:5432/azimutt_dev")

            size(:integer, "File size for file kinds (SqlLocalFile, SqlRemoteFile, PrismaLocalFile, PrismaRemoteFile, JsonLocalFile & JsonRemoteFile)", example: 1324)
            name(:string, "File name for local kinds (SqlLocalFile, PrismaLocalFile & JsonLocalFile)", example: "structure.sql")
            modified(:integer, "File last updated at for local kinds (SqlLocalFile, PrismaLocalFile & JsonLocalFile)", example: 1_682_781_320_168)
          end

          example([
            %{kind: "AmlEditor"},
            %{kind: "DatabaseConnection", url: "postgresql://postgres:postgres@localhost:5432/azimutt_dev"},
            %{kind: "SqlRemoteFile", url: "https://azimutt.app/elm/samples/basic.sql", size: 1764},
            %{kind: "PrismaRemoteFile", url: "https://azimutt.app/elm/samples/basic.prisma", size: 1511},
            %{kind: "JsonRemoteFile", url: "https://azimutt.app/elm/samples/basic.json", size: 4777},
            %{kind: "SqlLocalFile", name: "structure.sql", size: 1764, modified: 1_682_781_320_168},
            %{kind: "PrismaLocalFile", name: "schema.prisma", size: 1511, modified: 1_682_781_320_168},
            %{kind: "JsonLocalFile", name: "azimutt.json", size: 4777, modified: 1_682_781_320_168}
          ])
        end,
      SourceItem:
        swagger_schema do
          description("A project source without its content.")

          properties do
            id(:string, "Unique identifier", required: true, example: "cf29f83c-ab6d-460d-b625-1930c8ac17e2")
            name(:string, "Source name", required: true, example: "azimutt_dev")
            kind(Schema.ref(:SourceKind), "Source kind", required: true)
            createdAt(:integer, "Creation timestamp", required: true, example: 1_682_781_320_168)
            updatedAt(:integer, "Update timestamp", required: true, example: 1_682_781_320_168)
          end
        end,
      SourceComment:
        swagger_schema do
          description("A SQL comment from the source")

          properties do
            text(:string, "The comment text", required: true, example: "A SQL comment here")
          end
        end,
      SourceColumn:
        swagger_schema do
          description("A table column in a source")

          properties do
            name(:string, "The column name", required: true, example: "role")
            type(:string, "The column type", required: true, example: "varchar(10)")
            nullable(:boolean, "If the column is nullable", required: true, example: false)
            default(:string, "The column default value", example: "admin")
            comment(Schema.ref(:SourceComment), "The column comment in the source")
            values(:array, "Some possible values from the column", items: %{type: :string}, example: ["guest", "admin"])
            columns(:array, "Nested columns of this column, for JSON", items: Schema.ref(:SourceColumn))
          end
        end,
      SourcePrimaryKey:
        swagger_schema do
          description("A table primary key")

          properties do
            name(:text, "The primary key name", example: "users_pk")
            columns(:array, "List of columns in the primary key, can be path", required: true, items: %{type: :string}, example: ["user_id", "role_id"])
          end
        end,
      SourceIndexUnique:
        swagger_schema do
          description("A table unique index")

          properties do
            name(:text, "The unique index name", required: true, example: "project_slug_uniq")
            columns(:array, "List of columns in the index, can be path", required: true, items: %{type: :string}, example: ["organization_id", "slug"])
            definition(:text, "The definition of the index", example: "USING btree (organization_id, slug)")
          end
        end,
      SourceIndex:
        swagger_schema do
          description("A table index")

          properties do
            name(:text, "The index name", required: true, example: "user_name_index")
            columns(:array, "List of columns in the index, can be path", required: true, items: %{type: :string}, example: ["first_name", "last_name"])
            definition(:text, "The definition of the index", example: "USING btree (first_name, last_name)")
          end
        end,
      SourceCheckConstraint:
        swagger_schema do
          description("A table check constraint")

          properties do
            name(:text, "The check constraint name", required: true, example: "users_age_chk")
            columns(:array, "List of columns in the constraint, can be path", required: true, items: %{type: :string}, example: ["age"])
            predicate(:text, "The predicate of the constraint", example: "age > 0")
          end
        end,
      SourceTable:
        swagger_schema do
          description("A table in a source")

          properties do
            schema(:string, "The table schema", required: true, example: "public")
            table(:string, "The table name", required: true, example: "users")
            view(:boolean, "If the table is a view", required: true, example: false)
            columns(:array, "The columns of the table", required: true, items: Schema.ref(:SourceColumn))
            comment(Schema.ref(:SourcePrimaryKey), "The primary key of the table")
            uniques(:array, "The unique indexes of the table", items: Schema.ref(:SourceIndexUnique))
            indexes(:array, "The indexes of the table", items: Schema.ref(:SourceIndex))
            checks(:array, "The checks of the table", items: Schema.ref(:SourceCheckConstraint))
            comment(Schema.ref(:SourceComment), "The table comment in the source")
          end
        end,
      SourceColumnRef:
        swagger_schema do
          description("A relation in a source")

          properties do
            table(:string, "The table id referenced (ex: schema.table)", required: true, example: "public.users")
            column(:string, "The column path referenced (ex: name or details:theme)", required: true, example: "details:theme")
          end
        end,
      SourceRelation:
        swagger_schema do
          description("A relation in a source")

          properties do
            name(:string, "Relation name", required: true, example: "events_created_by_fk")
            src(Schema.ref(:SourceColumnRef), "Relation source", required: true)
            ref(Schema.ref(:SourceColumnRef), "Relation reference", required: true)
          end
        end,
      SourceType:
        swagger_schema do
          description("A custom type in a source")

          properties do
            schema(:string, "The type schema", required: true, example: "public")
            name(:string, "The type name", required: true, example: "role")

            value(
              Schema.new do
                properties do
                  enum(:array, "Values for the enum type", items: %{type: :string}, example: ["admin", "guest"])
                  definition(:string, "The definition of the type", example: "RANGE (subtype = float8, subtype_diff = float8mi)")
                end
              end,
              "The type value, either a definition or an enum",
              required: true,
              example: [%{enum: ["admin", "guest"]}, %{definition: "RANGE (subtype = float8, subtype_diff = float8mi)"}]
            )
          end
        end,
      SourceContent:
        swagger_schema do
          description("The content of a Source")

          properties do
            content(:array, "Source original content, list of lines in the file", items: %{type: :string})
            tables(:array, "Tables of the source", items: Schema.ref(:SourceTable))
            relations(:array, "Relations of the source", items: Schema.ref(:SourceRelation))
            types(:array, "Custom types of the source", items: Schema.ref(:SourceType))
          end
        end,
      Source:
        swagger_schema do
          description("A project Source")
          Schema.all_of([Schema.ref(:SourceItem), Schema.ref(:SourceContent)])
        end,
      SourceItems:
        swagger_schema do
          description("A collection of SourceItems")
          type(:array)
          items(Schema.ref(:SourceItem))
        end
    }
  end
end
