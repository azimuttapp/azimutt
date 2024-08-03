module DataSources.DbMiner.QueryMongoDB exposing (addLimit, exploreColumn, exploreTable, findRow)

import Libs.Bool as Bool
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Libs.Regex as Regex
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.RowPrimaryKey exposing (RowPrimaryKey)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.SqlQuery exposing (SqlQuery)


exploreTable : TableId -> SqlQuery
exploreTable ( schema, table ) =
    let
        ( collection, filter ) =
            mixedCollection table

        query : String
        query =
            filter |> Maybe.mapOrElse (\( field, value ) -> "{\"" ++ field ++ "\": \"" ++ value ++ "\"}") ""
    in
    buildDb schema ++ "." ++ collection ++ ".find(" ++ query ++ ");\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn ( schema, table ) column =
    let
        ( collection, filter ) =
            mixedCollection table

        whereClause : String
        whereClause =
            filter |> Maybe.mapOrElse (\( field, value ) -> "\n  {\"$match\": {\"" ++ field ++ "\": {\"$eq\": \"" ++ value ++ "\"}}},") ""
    in
    buildDb schema ++ "." ++ collection ++ ".aggregate([" ++ whereClause ++ "\n  {\"$sortByCount\": \"$" ++ column.head ++ "\"},\n  {\"$project\": {\"_id\": 0, \"" ++ column.head ++ "\": \"$_id\", \"count\": \"$count\"}}\n]);\n"



-- TODO: filterTable


findRow : TableId -> RowPrimaryKey -> SqlQuery
findRow ( schema, table ) primaryKey =
    let
        ( collection, filter ) =
            mixedCollection table

        whereClause : String
        whereClause =
            if primaryKey.head.column.head == "_id" then
                "ObjectId(" ++ formatValue primaryKey.head.value ++ ")"

            else
                "{"
                    ++ (filter |> Maybe.map (\( field, value ) -> "\"" ++ field ++ "\": \"" ++ value ++ "\"" ++ ", ") |> Maybe.withDefault "")
                    ++ (primaryKey |> Nel.toList |> List.map (\c -> "\"" ++ c.column.head ++ "\": " ++ formatValue c.value) |> String.join ", ")
                    ++ "}"
    in
    buildDb schema ++ "." ++ collection ++ ".find(" ++ whereClause ++ ").limit(1);"



-- TODO: incomingRows?


addLimit : SqlQuery -> SqlQuery
addLimit query =
    case query |> String.trim |> Regex.matches "^([\\s\\S]+?)(\\.limit\\(\\d+\\))?;?$" of
        (Just q) :: Nothing :: [] ->
            q ++ ".limit(100);\n"

        _ ->
            query



-- PRIVATE


buildDb : SchemaName -> String
buildDb schema =
    if schema == "" then
        "db"

    else
        "db('" ++ schema ++ "')"


mixedCollection : TableName -> ( TableName, Maybe ( String, String ) )
mixedCollection table =
    case table |> String.split "__" of
        [ collection, field, value ] ->
            ( collection, Just ( field, value ) )

        _ ->
            ( table, Nothing )


formatValue : DbValue -> String
formatValue value =
    case value of
        DbString s ->
            "\"" ++ s ++ "\""

        DbInt i ->
            String.fromInt i

        DbFloat f ->
            String.fromFloat f

        DbBool b ->
            Bool.cond b "true" "false"

        DbNull ->
            "null"

        _ ->
            "'" ++ DbValue.toJson value ++ "'"
