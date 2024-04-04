module DataSources.DbMiner.QueryMySQL exposing (addLimit, exploreColumn, exploreTable, filterTable, findRow, incomingRows, updateColumnType)

import DataSources.DbMiner.DbTypes exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, TableFilter)
import Dict exposing (Dict)
import Libs.Bool as Bool
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.RowPrimaryKey exposing (RowPrimaryKey)
import Models.Project.RowValue exposing (RowValue)
import Models.Project.TableId as TableId exposing (TableId)
import Models.SqlQuery exposing (SqlQuery)


exploreTable : TableId -> SqlQuery
exploreTable table =
    "SELECT *\nFROM " ++ formatTable table ++ ";\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn table column =
    formatColumn "" column |> (\col -> "SELECT\n  " ++ col ++ ",\n  count(*) as count\nFROM " ++ formatTable table ++ "\nGROUP BY " ++ col ++ "\nORDER BY count DESC, " ++ col ++ ";\n")


filterTable : TableId -> List TableFilter -> SqlQuery
filterTable table filters =
    "SELECT *\nFROM " ++ formatTable table ++ formatFilters filters ++ ";\n"


findRow : TableId -> RowPrimaryKey -> SqlQuery
findRow table primaryKey =
    "SELECT *\nFROM " ++ formatTable table ++ "\nWHERE " ++ formatMatcher primaryKey ++ "\nLIMIT 1;\n"


incomingRows : RowQuery -> Dict TableId IncomingRowsQuery -> Int -> SqlQuery
incomingRows query relations limit =
    "SELECT\n"
        ++ (relations
                |> Dict.toList
                |> List.map
                    (\( table, q ) ->
                        "  array(SELECT json_build_object("
                            ++ (q.primaryKey |> Nel.toList |> List.map (\( col, _ ) -> "'" ++ (col |> ColumnPath.toString) ++ "', " ++ formatColumn "s" col) |> String.join ", ")
                            ++ ")"
                            ++ " FROM "
                            ++ formatTable table
                            ++ " s WHERE "
                            ++ (q.foreignKeys |> List.map (\( fk, _ ) -> formatColumn "s" fk ++ " = " ++ formatColumn "m" query.primaryKey.head.column) |> String.join " OR ")
                            ++ " LIMIT "
                            ++ String.fromInt limit
                            ++ ") as `"
                            ++ TableId.toString table
                            ++ "`"
                    )
                |> String.join ",\n"
           )
        ++ "\nFROM "
        ++ formatTable query.table
        ++ " m\nWHERE "
        ++ formatMatcher query.primaryKey
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
    "ALTER TABLE " ++ formatTable ref.table ++ " MODIFY " ++ formatColumn "" ref.column ++ " " ++ kind ++ ";"



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
        "`" ++ table ++ "`"

    else
        "`" ++ schema ++ "`.`" ++ table ++ "`"


formatColumn : String -> ColumnPath -> String
formatColumn prefix column =
    -- FIXME: handle JSON columns
    if prefix == "" then
        "`" ++ column.head ++ "`"

    else
        prefix ++ ".`" ++ column.head ++ "`"


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
