module Services.DatabaseQueries exposing (showColumnData, showData, showTableData)

import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Services.QueryBuilder exposing (SqlFragment, SqlQuery)



-- FIXME merge into QueryBuilder


showData : Maybe ColumnPath -> TableId -> DatabaseUrl -> SqlQuery
showData column =
    column |> Maybe.map showColumnData |> Maybe.withDefault showTableData


showTableData : TableId -> DatabaseUrl -> SqlQuery
showTableData ( schema, table ) url =
    case DatabaseKind.fromUrl url of
        DatabaseKind.Couchbase ->
            let
                ( collection, filter ) =
                    mixedCollection table

                whereClause : String
                whereClause =
                    filter |> Maybe.mapOrElse (\( field, value ) -> " WHERE " ++ field ++ "='" ++ value ++ "'") ""
            in
            "SELECT " ++ couchbaseEscape collection ++ ".* FROM " ++ couchbaseCollectionRef schema collection ++ whereClause ++ " LIMIT " ++ limit ++ ";"

        DatabaseKind.MariaDB ->
            defaultShowTableData schema table

        DatabaseKind.MongoDB ->
            let
                ( collection, filter ) =
                    mixedCollection table

                query : String
                query =
                    filter |> Maybe.mapOrElse (\( field, value ) -> "{\"" ++ field ++ "\":\"" ++ value ++ "\"}") "{}"
            in
            schema ++ "/" ++ collection ++ "/find/" ++ query ++ "/" ++ limit

        DatabaseKind.MySQL ->
            defaultShowTableData schema table

        DatabaseKind.PostgreSQL ->
            defaultShowTableData schema table

        DatabaseKind.SQLServer ->
            "SELECT TOP " ++ limit ++ " * FROM " ++ tableRef schema table ++ ";"

        DatabaseKind.Other ->
            defaultShowTableData schema table


defaultShowTableData : SchemaName -> TableName -> SqlQuery
defaultShowTableData schema table =
    "SELECT *\nFROM " ++ tableRef schema table ++ "\nLIMIT " ++ limit ++ ";\n"


showColumnData : ColumnPath -> TableId -> DatabaseUrl -> SqlQuery
showColumnData column ( schema, table ) url =
    case DatabaseKind.fromUrl url of
        DatabaseKind.Couchbase ->
            let
                ( collection, filter ) =
                    mixedCollection table

                whereClause : String
                whereClause =
                    filter |> Maybe.mapOrElse (\( field, value ) -> " WHERE " ++ field ++ "='" ++ value ++ "'") ""
            in
            "SELECT " ++ couchbaseEscape collection ++ "." ++ column.head ++ ", COUNT(*) as count FROM " ++ couchbaseCollectionRef schema collection ++ whereClause ++ " GROUP BY " ++ column.head ++ " ORDER BY count DESC LIMIT " ++ limit ++ ";"

        DatabaseKind.MariaDB ->
            defaultShowColumnData schema table column.head

        DatabaseKind.MongoDB ->
            let
                ( collection, filter ) =
                    mixedCollection table

                whereClause : String
                whereClause =
                    filter |> Maybe.mapOrElse (\( field, value ) -> "{\"$match\":{\"" ++ field ++ "\":{\"$eq\":\"" ++ value ++ "\"}}},") ""
            in
            schema ++ "/" ++ collection ++ "/aggregate/[" ++ whereClause ++ "{\"$sortByCount\":\"$" ++ column.head ++ "\"},{\"$project\":{\"_id\":0,\"" ++ column.head ++ "\":\"$_id\",\"count\":\"$count\"}}]/" ++ limit

        DatabaseKind.MySQL ->
            defaultShowColumnData schema table column.head

        DatabaseKind.PostgreSQL ->
            ( postgresColumn column, postgresColumnAlias column )
                |> (\( col, alias ) -> "SELECT\n  " ++ Bool.cond (col == alias) col (col ++ " as " ++ alias) ++ ",\n  count(*)\nFROM " ++ tableRef schema table ++ "\nGROUP BY " ++ col ++ "\nORDER BY count DESC, " ++ alias ++ "\nLIMIT " ++ limit ++ ";\n")

        DatabaseKind.SQLServer ->
            "SELECT TOP " ++ limit ++ " " ++ column.head ++ ", count(*) as count FROM " ++ tableRef schema table ++ " GROUP BY " ++ column.head ++ " ORDER BY count DESC, " ++ column.head ++ ";"

        DatabaseKind.Other ->
            defaultShowColumnData schema table column.head


defaultShowColumnData : SchemaName -> TableName -> ColumnName -> String
defaultShowColumnData schema table column =
    "SELECT " ++ column ++ ", count(*) as count FROM " ++ tableRef schema table ++ " GROUP BY " ++ column ++ " ORDER BY count DESC, " ++ column ++ " LIMIT " ++ limit ++ ";"


tableRef : SchemaName -> TableName -> String
tableRef schema table =
    if schema /= "" then
        "\"" ++ schema ++ "\".\"" ++ table ++ "\""

    else
        "\"" ++ table ++ "\""


postgresColumn : ColumnPath -> SqlFragment
postgresColumn column =
    "\"" ++ column.head ++ "\"" ++ (column.tail |> List.map (\c -> "->'" ++ c ++ "'") |> String.join "")


postgresColumnAlias : ColumnPath -> SqlFragment
postgresColumnAlias column =
    "\"" ++ (column.tail |> List.last |> Maybe.withDefault column.head) ++ "\""


couchbaseCollectionRef : SchemaName -> TableName -> String
couchbaseCollectionRef schema table =
    schema
        |> String.split "__"
        |> List.add table
        |> List.map couchbaseEscape
        |> String.join "."


couchbaseEscape : String -> String
couchbaseEscape v =
    if (v |> String.contains "-") || (v |> String.contains " ") then
        "`" ++ v ++ "`"

    else
        v


mixedCollection : TableName -> ( TableName, Maybe ( String, String ) )
mixedCollection table =
    case table |> String.split "__" of
        [ collection, field, value ] ->
            ( collection, Just ( field, value ) )

        _ ->
            ( table, Nothing )


limit : String
limit =
    "100"
