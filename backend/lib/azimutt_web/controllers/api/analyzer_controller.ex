defmodule AzimuttWeb.Api.AnalyzerController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Analyzer
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :schema do
    get("/api/v1/analyzer/schema")
    summary("Extract a database schema")
    description("Extract a database schema from your database url, nothing is stored")
    produces("application/json")
    tag("Analyzer")
    operation_id("analyze_schema")

    parameters do
      url(:query, :string, "Database URL",
        required: true,
        example: "postgres://postgres:postgres@localhost:5432/my_db"
      )

      schema(:query, :string, "Database schema", example: "public")
    end

    response(200, "OK", Schema.ref(:Schema))
  end

  def schema(conn, %{"url" => url} = params) do
    with {:ok, %Analyzer.Schema{} = schema} <- Analyzer.get_schema(url, params["schema"]),
         do: conn |> render("schema.json", schema: schema)
  end

  def swagger_definitions do
    %{
      Schema:
        swagger_schema do
          title("Schema")
          description("The schema of your database")

          properties do
            tables(array(:Table), "All your tables", required: true)
            relations(array(:Relation), "All relations between columns", required: true)
            types(array(:Type), "Types defined in your database", required: true)
          end
        end,
      Table:
        swagger_schema do
          title("Table")
          description("A table")

          properties do
            schema(:string, "Table schema", required: true, example: "public")
            table(:string, "Table name", required: true, example: "users")
            view(:bool, "When it's a view", required: true, example: false)
            columns(array(:Column), "Table columns", required: true)
            primaryKey(Schema.ref(:PrimaryKey), "Table primary key")
            uniques(array(:Unique), "Table unique constraints", required: true)
            indexes(array(:Index), "Table indexes", required: true)
            checks(array(:Check), "Table check constraints", required: true)
            comment(:string, "Table comment", example: "store all users")
          end
        end,
      Column:
        swagger_schema do
          title("Column")
          description("A table column")

          properties do
            name(:string, "Column name", required: true, example: "email")
            type(:string, "Column type", required: true, example: "varchar(128)")
            nullable(:bool, "Is nullable", required: true, example: false)
            default(:string, "Column default value", example: "default@example.com")
            comment(:string, "Column comment", example: "store use email")
          end
        end,
      PrimaryKey:
        swagger_schema do
          title("PrimaryKey")
          description("A primary key")

          properties do
            name(:string, "Primary key name", example: "users_pk")

            columns(array(:string), "Involved columns in the primary key",
              required: true,
              example: ["id"]
            )
          end
        end,
      Unique:
        swagger_schema do
          title("Unique")
          description("An unique index")

          properties do
            name(:string, "Unique name", required: true, example: "users_email_uniq")

            columns(array(:string), "Involved columns in the unique index",
              required: true,
              example: ["email"]
            )

            definition(:string, "Unique index definition")
          end
        end,
      Index:
        swagger_schema do
          title("Index")
          description("An index")

          properties do
            name(:string, "Index name", required: true, example: "users_email_idx")

            columns(array(:string), "Involved columns in the index",
              required: true,
              example: ["email"]
            )

            definition(:string, "Index definition")
          end
        end,
      Check:
        swagger_schema do
          title("Check")
          description("A check constraint")

          properties do
            name(:string, "Constraint name", required: true, example: "users_name_len")

            columns(array(:string), "Involved columns in the constraint",
              required: true,
              example: ["name"]
            )

            predicate(:string, "Constraint definition", example: "LEN(name) > 3")
          end
        end,
      Relation:
        swagger_schema do
          title("Relation")
          description("A relation between two tables")

          properties do
            name(:string, "Relation name", required: true, example: "orga_users_fk")
            src(Schema.ref(:TableRef), "Table source", required: true)
            ref(Schema.ref(:TableRef), "Referenced table", required: true)
            columns(array(:ColumnLink), "Columns involved in the relation", required: true)
          end
        end,
      TableRef:
        swagger_schema do
          title("TableRef")
          description("A reference of a table")

          properties do
            schema(:string, "Table schema", required: true, example: "public")
            table(:string, "Table name", required: true, example: "users")
          end
        end,
      ColumnLink:
        swagger_schema do
          title("ColumnLink")
          description("Linked columns in the relation")

          properties do
            src(:string, "foreign key", required: true, example: "user_id")
            ref(:string, "reference", required: true, example: "id")
          end
        end,
      Type:
        swagger_schema do
          title("Type")
          description("A custom type defined in your database schema")

          properties do
            schema(:string, "Schema name", required: true, example: "public")
            name(:string, "Type name", required: true, example: "user_role")
            values(array(:string), "Type values for enums", example: ["admin", "guest"])
          end
        end
    }
  end
end
