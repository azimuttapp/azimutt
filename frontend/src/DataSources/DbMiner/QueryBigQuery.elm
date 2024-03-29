module DataSources.DbMiner.QueryBigQuery exposing (addLimit, exploreColumn, exploreTable)

import Libs.Regex as Regex
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)
import Models.SqlQuery exposing (SqlQuery)


exploreTable : TableId -> SqlQuery
exploreTable table =
    "SELECT *\nFROM " ++ formatTable table ++ ";\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn table column =
    formatColumn column
        |> (\col -> "SELECT\n  " ++ col ++ ",\n  count(*) AS count\nFROM " ++ formatTable table ++ "\nGROUP BY " ++ col ++ "\nORDER BY count DESC, " ++ col ++ ";\n")


addLimit : SqlQuery -> SqlQuery
addLimit query =
    case query |> String.trim |> Regex.matches "^([\\s\\S]+?)(\\slimit \\d+)?(\\soffset \\d+)?;$" of
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
        "`" ++ table ++ "`"

    else
        "`" ++ schema ++ "`" ++ "." ++ "`" ++ table ++ "`"


formatColumn : ColumnPath -> String
formatColumn column =
    "`" ++ column.head ++ "`"
