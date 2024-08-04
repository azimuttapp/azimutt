module DataSources.DbMiner.QuerySQLServer exposing (addLimit, exploreColumn, exploreTable, filterTable, findRow, incomingRows, updateColumnType)

import DataSources.DbMiner.DbTypes exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, TableFilter)
import Dict exposing (Dict)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.RowPrimaryKey exposing (RowPrimaryKey, labelColName)
import Models.Project.RowValue exposing (RowValue)
import Models.Project.TableId as TableId exposing (TableId)
import Models.SqlFragment exposing (SqlFragment)
import Models.SqlQuery exposing (SqlQuery)


exploreTable : TableId -> SqlQuery
exploreTable table =
    "SELECT *\nFROM " ++ formatTable table ++ ";\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn table column =
    ( formatColumn "" column, formatColumnAlias column )
        |> (\( col, alias ) -> "SELECT\n  " ++ col ++ Bool.cond (col == alias) "" (" AS " ++ alias) ++ ",\n  count(*) AS count\nFROM " ++ formatTable table ++ "\nGROUP BY " ++ col ++ "\nORDER BY count DESC, " ++ alias ++ ";\n")


filterTable : TableId -> List TableFilter -> SqlQuery
filterTable table filters =
    "SELECT *\nFROM " ++ formatTable table ++ formatFilters filters ++ ";\n"


findRow : TableId -> RowPrimaryKey -> SqlQuery
findRow table primaryKey =
    "SELECT TOP 1 *\nFROM " ++ formatTable table ++ "\nWHERE " ++ formatMatcher primaryKey ++ ";\n"


incomingRows : DbValue -> Dict TableId IncomingRowsQuery -> Int -> SqlQuery
incomingRows value relations limit =
    "SELECT TOP 1\n"
        ++ (relations
                |> Dict.toList
                |> List.map
                    (\( table, q ) ->
                        ("  (SELECT TOP " ++ String.fromInt limit ++ " ")
                            ++ (if q.labelCols |> List.isEmpty then
                                    ""

                                else
                                    (q.labelCols |> List.map (\( col, _ ) -> formatColumn "s" col) |> List.intersperse "' '" |> String.join " + ") ++ " AS '" ++ labelColName ++ "', "
                               )
                            ++ (q.primaryKey |> Nel.toList |> List.map (\( col, _ ) -> formatColumn "s" col ++ " AS '" ++ (col |> ColumnPath.toString) ++ "'") |> String.join ", ")
                            ++ (" FROM " ++ formatTable table ++ " s")
                            ++ (" WHERE " ++ (q.foreignKeys |> List.map (\( fk, _ ) -> formatColumn "s" fk ++ "=" ++ formatValue value) |> String.join " OR "))
                            ++ (" FOR JSON PATH) AS [" ++ TableId.toString table ++ "]")
                    )
                |> String.join ",\n"
           )
        ++ ";\n"


addLimit : SqlQuery -> SqlQuery
addLimit query =
    case query |> String.trim |> Regex.matches "^(select)(\\s+top \\d+)?([\\s\\S]+?;)$" of
        (Just s) :: Nothing :: (Just q) :: [] ->
            s ++ " TOP 100" ++ q ++ "\n"

        _ ->
            query


updateColumnType : ColumnRef -> ColumnType -> SqlQuery
updateColumnType ref kind =
    "ALTER TABLE " ++ formatTable ref.table ++ " ALTER COLUMN " ++ formatColumn "" ref.column ++ " " ++ kind ++ ";"



-- PRIVATE


formatFilters : List TableFilter -> String
formatFilters filters =
    if filters |> List.isEmpty then
        ""

    else
        "\nWHERE "
            ++ (filters
                    |> List.indexedMap
                        (\i f ->
                            if i == 0 then
                                formatFilter f

                            else
                                formatOperator f.operator ++ " " ++ formatFilter f
                        )
                    |> String.join " "
               )


formatFilter : TableFilter -> String
formatFilter filter =
    formatColumn "" filter.column ++ formatOperation filter.operation filter.value


formatMatcher : Nel RowValue -> String
formatMatcher matches =
    matches |> Nel.toList |> List.map (\m -> formatColumn "" m.column ++ "=" ++ formatValue m.value) |> String.join " AND "



-- generic helpers


formatTable : TableId -> String
formatTable ( schema, table ) =
    if schema == "" then
        "[" ++ table ++ "]"

    else
        "[" ++ schema ++ "].[" ++ table ++ "]"


formatColumn : String -> ColumnPath -> String
formatColumn prefix column =
    let
        baseCol : String
        baseCol =
            if prefix == "" then
                "[" ++ column.head ++ "]"

            else
                prefix ++ ".[" ++ column.head ++ "]"
    in
    if List.isEmpty column.tail then
        baseCol

    else
        "JSON_VALUE(" ++ baseCol ++ ", '$." ++ (column.tail |> String.join ".") ++ "')"


formatColumnAlias : ColumnPath -> SqlFragment
formatColumnAlias column =
    "[" ++ (column.tail |> List.last |> Maybe.withDefault column.head) ++ "]"


formatOperator : FilterOperator -> String
formatOperator op =
    case op of
        DbAnd ->
            "AND"

        DbOr ->
            "OR"


formatOperation : FilterOperation -> DbValue -> String
formatOperation op value =
    case op of
        DbEqual ->
            "=" ++ formatValue value

        DbNotEqual ->
            "!=" ++ formatValue value

        DbIsNull ->
            " IS NULL"

        DbIsNotNull ->
            " IS NOT NULL"

        DbGreaterThan ->
            ">" ++ formatValue value

        DbLesserThan ->
            "<" ++ formatValue value

        DbLike ->
            " LIKE " ++ formatValue value


formatValue : DbValue -> String
formatValue value =
    case value of
        DbString s ->
            "'" ++ s ++ "'"

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
