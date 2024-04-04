module DataSources.DbMiner.QuerySQLServer exposing (addLimit, exploreColumn, exploreTable)

import Libs.Regex as Regex
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)
import Models.SqlQuery exposing (SqlQuery)


exploreTable : TableId -> SqlQuery
exploreTable table =
    "SELECT * FROM " ++ formatTable table ++ ";\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn table column =
    formatColumn column |> (\col -> "SELECT\n  " ++ col ++ ",\n  count(*) as count\nFROM " ++ formatTable table ++ "\nGROUP BY " ++ col ++ "\nORDER BY count DESC, " ++ col ++ ";\n")


addLimit : SqlQuery -> SqlQuery
addLimit query =
    case query |> String.trim |> Regex.matches "^(select)(\\s+top \\d+)?([\\s\\S]+?;)$" of
        (Just s) :: Nothing :: (Just q) :: [] ->
            s ++ " TOP 100" ++ q ++ "\n"

        _ ->
            query



-- PRIVATE


formatTable : TableId -> String
formatTable ( schema, table ) =
    if schema == "" then
        "\"" ++ table ++ "\""

    else
        "\"" ++ schema ++ "\"" ++ "." ++ "\"" ++ table ++ "\""


formatColumn : ColumnPath -> String
formatColumn column =
    -- FIXME: handle JSON columns
    "\"" ++ column.head ++ "\""
