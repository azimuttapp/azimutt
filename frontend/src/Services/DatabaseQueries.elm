module Services.DatabaseQueries exposing (showColumnData, showData, showTableData)

import Libs.List as List
import Libs.Models.DatabaseKind as DatabaseKind
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)


showData : Maybe ColumnPath -> TableId -> DatabaseUrl -> String
showData column =
    column |> Maybe.map showColumnData |> Maybe.withDefault showTableData


showTableData : TableId -> DatabaseUrl -> String
showTableData ( schema, table ) url =
    case DatabaseKind.fromUrl url of
        DatabaseKind.MongoDB ->
            schema ++ "/" ++ table ++ "/find/{}/" ++ limit

        DatabaseKind.Couchbase ->
            "SELECT " ++ table ++ ".* FROM " ++ couchbaseTableRef schema table ++ " LIMIT " ++ limit ++ ";"

        DatabaseKind.PostgreSQL ->
            "SELECT * FROM " ++ tableRef schema table ++ " LIMIT " ++ limit ++ ";"

        DatabaseKind.Other ->
            "SELECT * FROM " ++ tableRef schema table ++ " LIMIT " ++ limit ++ ";"


showColumnData : ColumnPath -> TableId -> DatabaseUrl -> String
showColumnData column ( schema, table ) url =
    case DatabaseKind.fromUrl url of
        DatabaseKind.MongoDB ->
            schema ++ "/" ++ table ++ "/aggregate/[{\"$sortByCount\":\"$" ++ column.head ++ "\"},{\"$project\":{\"_id\":0,\"" ++ column.head ++ "\":\"$_id\",\"count\":\"$count\"}}]/" ++ limit

        DatabaseKind.Couchbase ->
            "SELECT " ++ table ++ "." ++ column.head ++ ", COUNT(*) as count FROM " ++ couchbaseTableRef schema table ++ " GROUP BY " ++ column.head ++ " ORDER BY count DESC LIMIT " ++ limit ++ ";"

        DatabaseKind.PostgreSQL ->
            "SELECT " ++ column.head ++ ", count(*) FROM " ++ tableRef schema table ++ " GROUP BY " ++ column.head ++ " ORDER BY count DESC, " ++ column.head ++ " LIMIT " ++ limit ++ ";"

        DatabaseKind.Other ->
            "SELECT " ++ column.head ++ ", count(*) FROM " ++ tableRef schema table ++ " GROUP BY " ++ column.head ++ " ORDER BY count DESC, " ++ column.head ++ " LIMIT " ++ limit ++ ";"


tableRef : SchemaName -> TableName -> String
tableRef schema table =
    if schema /= "" then
        schema ++ "." ++ table

    else
        table


couchbaseTableRef : SchemaName -> TableName -> String
couchbaseTableRef schema table =
    schema
        |> String.split "__"
        |> List.add table
        |> List.map
            (\v ->
                if (v |> String.contains "-") || (v |> String.contains " ") then
                    "`" ++ v ++ "`"

                else
                    v
            )
        |> String.join "."


limit : String
limit =
    "30"
