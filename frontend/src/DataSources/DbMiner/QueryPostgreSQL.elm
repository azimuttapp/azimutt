module DataSources.DbMiner.QueryPostgreSQL exposing (addLimit, exploreColumn, exploreTable, filterTable, findRow, incomingRows, updateColumnType)

import DataSources.DbMiner.DbTypes exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, TableFilter, TableQuery)
import Dict exposing (Dict)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType as ColumnType exposing (ColumnType, ParsedColumnType)
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
    -- FIXME: formatColumn
    ( formatColumn "" column ColumnType.Text, formatColumnAlias column )
        |> (\( col, alias ) -> "SELECT\n  " ++ Bool.cond (col == alias) col (col ++ " as " ++ alias) ++ ",\n  count(*)\nFROM " ++ formatTable table ++ "\nGROUP BY " ++ col ++ "\nORDER BY count DESC, " ++ alias ++ ";\n")


filterTable : TableId -> List TableFilter -> SqlQuery
filterTable table filters =
    "SELECT *\nFROM " ++ formatTable table ++ formatFilters filters ++ ";\n"


findRow : TableId -> RowPrimaryKey -> SqlQuery
findRow table primaryKey =
    "SELECT *\nFROM " ++ formatTable table ++ "\nWHERE " ++ formatMatcher primaryKey ++ "\nLIMIT 1;\n"


incomingRows : DbValue -> Dict TableId IncomingRowsQuery -> Int -> SqlQuery
incomingRows value relations limit =
    "SELECT\n"
        ++ (relations
                |> Dict.toList
                |> List.map
                    (\( table, q ) ->
                        "  array(SELECT json_build_object("
                            ++ (if q.labelCols |> List.isEmpty then
                                    ""

                                else
                                    "'" ++ labelColName ++ "', CONCAT(" ++ (q.labelCols |> List.map (\( col, kind ) -> formatColumn "s" col (ColumnType.parse kind)) |> List.intersperse "' '" |> String.join ", ") ++ "), "
                               )
                            ++ (q.primaryKey |> Nel.toList |> List.map (\( col, kind ) -> "'" ++ (col |> ColumnPath.toString) ++ "', " ++ formatColumn "s" col (ColumnType.parse kind)) |> String.join ", ")
                            ++ ")"
                            ++ (" FROM " ++ formatTable table ++ " s")
                            ++ (" WHERE " ++ (q.foreignKeys |> List.map (\( fk, kind ) -> formatColumn "s" fk (ColumnType.parse kind) ++ "=" ++ formatValue value) |> String.join " OR "))
                            ++ (" LIMIT " ++ String.fromInt limit)
                            ++ (") AS \"" ++ TableId.toString table ++ "\"")
                    )
                |> String.join ",\n"
           )
        ++ "\nLIMIT 1;\n"


addLimit : SqlQuery -> SqlQuery
addLimit query =
    case query |> String.trim |> Regex.matches "^(select[\\s\\S]+?)(\\slimit \\d+)?(\\soffset \\d+)?;$" of
        (Just q) :: Nothing :: Nothing :: [] ->
            q ++ "\nLIMIT 100;\n"

        (Just q) :: Nothing :: (Just offset) :: [] ->
            q ++ "\nLIMIT 100" ++ offset ++ ";\n"

        _ ->
            query


updateColumnType : ColumnRef -> ColumnType -> SqlQuery
updateColumnType ref kind =
    "ALTER TABLE " ++ formatTable ref.table ++ " ALTER COLUMN " ++ formatColumn "" ref.column ColumnType.Text ++ " TYPE " ++ kind ++ ";"



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
    formatColumn "" filter.column (DbValue.toType filter.value) ++ formatOperation filter.operation filter.value


formatMatcher : Nel RowValue -> String
formatMatcher matches =
    matches |> Nel.toList |> List.map (\m -> formatColumn "" m.column (DbValue.toType m.value) ++ "=" ++ formatValue m.value) |> String.join " AND "



-- generic helpers


formatTable : TableId -> String
formatTable ( schema, table ) =
    if schema == "" then
        "\"" ++ table ++ "\""

    else
        "\"" ++ schema ++ "\"" ++ "." ++ "\"" ++ table ++ "\""


formatColumn : String -> ColumnPath -> ParsedColumnType -> String
formatColumn prefix column kind =
    let
        baseCol : String
        baseCol =
            if prefix == "" then
                "\"" ++ column.head ++ "\""

            else
                prefix ++ ".\"" ++ column.head ++ "\""
    in
    case column.tail |> List.reverse of
        last :: rest ->
            baseCol ++ (rest |> List.reverse |> List.map (\c -> "->'" ++ c ++ "'") |> String.join "") ++ "->>'" ++ last ++ "'" |> formatColumnCast kind

        [] ->
            baseCol


formatColumnCast : ParsedColumnType -> String -> String
formatColumnCast kind sqlColumn =
    case kind of
        ColumnType.Int ->
            "(" ++ sqlColumn ++ ")::int"

        ColumnType.Float ->
            "(" ++ sqlColumn ++ ")::float"

        ColumnType.Bool ->
            "(" ++ sqlColumn ++ ")::boolean"

        ColumnType.Uuid ->
            "(" ++ sqlColumn ++ ")::uuid"

        _ ->
            sqlColumn


formatColumnAlias : ColumnPath -> SqlFragment
formatColumnAlias column =
    "\"" ++ (column.tail |> List.last |> Maybe.withDefault column.head) ++ "\""


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
