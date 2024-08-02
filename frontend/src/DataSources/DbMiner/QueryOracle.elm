module DataSources.DbMiner.QueryOracle exposing (addLimit, exploreColumn, exploreTable, filterTable, findRow, incomingRows)

import DataSources.DbMiner.DbTypes exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, TableFilter)
import Dict exposing (Dict)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
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
    ( formatColumn column, formatColumnAlias column )
        |> (\( col, alias ) -> "SELECT\n  t." ++ Bool.cond (col == alias) col (col ++ " AS " ++ alias) ++ ",\n  count(*) AS COUNT\nFROM " ++ formatTable table ++ " t\nGROUP BY t." ++ col ++ "\nORDER BY COUNT DESC, " ++ alias ++ ";\n")


filterTable : TableId -> List TableFilter -> SqlQuery
filterTable table filters =
    "SELECT *\nFROM " ++ formatTable table ++ " t" ++ formatFilters "t" filters ++ ";\n"


findRow : TableId -> RowPrimaryKey -> SqlQuery
findRow table primaryKey =
    "SELECT *\nFROM " ++ formatTable table ++ "\nWHERE " ++ formatMatcher primaryKey ++ "\nFETCH FIRST 1 ROW ONLY;\n"


incomingRows : DbValue -> Dict TableId IncomingRowsQuery -> Int -> SqlQuery
incomingRows value relations limit =
    "SELECT\n"
        ++ (relations
                |> Dict.toList
                |> List.map
                    (\( table, q ) ->
                        "  JSON_ARRAY((SELECT JSON_OBJECT("
                            ++ (if q.labelCols |> List.isEmpty then
                                    ""

                                else
                                    "'" ++ labelColName ++ "' VALUE " ++ (q.labelCols |> List.map (\( col, _ ) -> "s." ++ formatColumn col) |> List.intersperse "' '" |> String.join " || ") ++ ", "
                               )
                            ++ (q.primaryKey |> Nel.toList |> List.map (\( col, _ ) -> "'" ++ (col |> ColumnPath.toString) ++ "' VALUE s." ++ formatColumn col) |> String.join ", ")
                            ++ ")"
                            ++ (" FROM " ++ formatTable table ++ " s")
                            ++ (" WHERE " ++ (q.foreignKeys |> List.map (\( fk, _ ) -> "s." ++ formatColumn fk ++ "=" ++ formatValue value) |> String.join " OR "))
                            ++ (" FETCH FIRST " ++ String.fromInt limit ++ " ROWS ONLY)")
                            ++ (" RETURNING JSON) AS \"" ++ TableId.toString table ++ "\"")
                    )
                |> String.join ",\n"
           )
        ++ "\nFETCH FIRST 1 ROW ONLY;\n"


addLimit : SqlQuery -> SqlQuery
addLimit query =
    case query |> String.trim |> Regex.matches "^(select[\\s\\S]+?)(\\s+offset \\d+ rows?)?(\\s+fetch (?:first|next) \\d+ rows? only)?\\s*;$" of
        (Just q) :: Nothing :: Nothing :: [] ->
            q ++ "\nFETCH FIRST 100 ROWS ONLY;\n"

        (Just q) :: (Just offset) :: Nothing :: [] ->
            q ++ "\n" ++ String.trim offset ++ " FETCH FIRST 100 ROWS ONLY;\n"

        _ ->
            query



-- generic helpers


formatTable : TableId -> String
formatTable ( schema, table ) =
    if schema == "" then
        "\"" ++ table ++ "\""

    else
        "\"" ++ schema ++ "\"" ++ "." ++ "\"" ++ table ++ "\""


formatColumn : ColumnPath -> String
formatColumn column =
    "\"" ++ column.head ++ "\"" ++ (column.tail |> List.map (\c -> "." ++ c) |> String.join "")


formatColumnAlias : ColumnPath -> SqlFragment
formatColumnAlias column =
    "\"" ++ (column.tail |> List.last |> Maybe.withDefault column.head) ++ "\""


formatMatcher : Nel RowValue -> String
formatMatcher matches =
    matches |> Nel.toList |> List.map (\m -> formatColumn m.column ++ "=" ++ formatValue m.value) |> String.join " AND "


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


formatFilters : String -> List TableFilter -> String
formatFilters scope filters =
    if filters |> List.isEmpty then
        ""

    else
        "\nWHERE "
            ++ (filters
                    |> List.indexedMap
                        (\i f ->
                            if i == 0 then
                                formatFilter scope f

                            else
                                formatOperator f.operator ++ " " ++ formatFilter scope f
                        )
                    |> String.join " "
               )


formatFilter : String -> TableFilter -> String
formatFilter scope filter =
    scope ++ "." ++ formatColumn filter.column ++ formatOperation filter.operation filter.value


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
