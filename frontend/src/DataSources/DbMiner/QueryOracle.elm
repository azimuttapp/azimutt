module DataSources.DbMiner.QueryOracle exposing (addLimit, exploreColumn, exploreTable)

import Libs.Bool as Bool
import Libs.List as List
import Libs.Regex as Regex
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)
import Models.SqlFragment exposing (SqlFragment)
import Models.SqlQuery exposing (SqlQuery)


exploreTable : TableId -> SqlQuery
exploreTable table =
    "SELECT *\nFROM " ++ formatTable table ++ ";\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn table column =
    -- FIXME: formatColumn
    ( formatColumn "" column, formatColumnAlias column )
        |> (\( col, alias ) -> "SELECT\n  t." ++ Bool.cond (col == alias) col (col ++ " AS " ++ alias) ++ ",\n  count(*) AS COUNT\nFROM " ++ formatTable table ++ " t\nGROUP BY t." ++ col ++ "\nORDER BY COUNT DESC, " ++ alias ++ ";\n")


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


formatColumn : String -> ColumnPath -> String
formatColumn prefix column =
    let
        baseCol : String
        baseCol =
            if prefix == "" then
                "\"" ++ column.head ++ "\""

            else
                prefix ++ ".\"" ++ column.head ++ "\""
    in
    baseCol ++ (column.tail |> List.map (\c -> "." ++ c) |> String.join "")


formatColumnAlias : ColumnPath -> SqlFragment
formatColumnAlias column =
    "\"" ++ (column.tail |> List.last |> Maybe.withDefault column.head) ++ "\""
