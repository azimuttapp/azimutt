module DataSources.DbMiner.QueryOracle exposing (addLimit, exploreColumn, exploreTable)

import Libs.Bool as Bool
import Libs.List as List
import Libs.Regex as Regex
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ParsedColumnType)
import Models.Project.TableId exposing (TableId)
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


addLimit : SqlQuery -> SqlQuery
addLimit query =
    case query |> String.trim |> Regex.matches "^(select[\\s\\S]+?)(\\slimit \\d+)?(\\soffset \\d+)?;$" of
        (Just q) :: Nothing :: Nothing :: [] ->
            q ++ "\nLIMIT 100;\n"

        (Just q) :: Nothing :: (Just offset) :: [] ->
            q ++ "\nLIMIT 100" ++ offset ++ ";\n"

        _ ->
            query



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
