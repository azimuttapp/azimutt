module DataSources.DbMiner.QueryCouchbase exposing (exploreColumn, exploreTable)

import Libs.List as List
import Libs.Maybe as Maybe
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.SqlQuery exposing (SqlQuery)



-- FIXME: remove hardcoded limits & implement `addLimit`


exploreTable : TableId -> SqlQuery
exploreTable ( schema, table ) =
    let
        ( collection, filter ) =
            mixedCollection table

        whereClause : String
        whereClause =
            filter |> Maybe.mapOrElse (\( field, value ) -> "\nWHERE " ++ field ++ "='" ++ value ++ "'") ""
    in
    "SELECT " ++ shouldEscape collection ++ ".*\nFROM " ++ collectionRef schema collection ++ whereClause ++ "\nLIMIT 100;\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn ( schema, table ) column =
    let
        ( collection, filter ) =
            mixedCollection table

        whereClause : String
        whereClause =
            filter |> Maybe.mapOrElse (\( field, value ) -> "\nWHERE " ++ field ++ "='" ++ value ++ "'") ""
    in
    "SELECT\n  " ++ shouldEscape collection ++ "." ++ column.head ++ ",\n  COUNT(*) as count\nFROM " ++ collectionRef schema collection ++ whereClause ++ "\nGROUP BY " ++ column.head ++ "\nORDER BY count DESC\nLIMIT 100;\n"



-- PRIVATE


mixedCollection : TableName -> ( TableName, Maybe ( String, String ) )
mixedCollection table =
    case table |> String.split "__" of
        [ collection, field, value ] ->
            ( collection, Just ( field, value ) )

        _ ->
            ( table, Nothing )


collectionRef : SchemaName -> TableName -> String
collectionRef schema table =
    schema
        |> String.split "__"
        |> List.add table
        |> List.map shouldEscape
        |> String.join "."


shouldEscape : String -> String
shouldEscape v =
    if (v |> String.contains "-") || (v |> String.contains " ") then
        "`" ++ v ++ "`"

    else
        v
