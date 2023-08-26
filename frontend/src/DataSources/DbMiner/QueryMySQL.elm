module DataSources.DbMiner.QueryMySQL exposing (exploreColumn, exploreTable)

import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)
import Models.SqlQuery exposing (SqlQuery)



-- FIXME: remove hardcoded limits & implement `addLimit`


exploreTable : TableId -> SqlQuery
exploreTable table =
    "SELECT *\nFROM " ++ formatTable table ++ "\nLIMIT 100;\n"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn table column =
    formatColumn column |> (\col -> "SELECT\n  " ++ col ++ ",\n  count(*) as count\nFROM " ++ formatTable table ++ "\nGROUP BY " ++ col ++ "\nORDER BY count DESC, " ++ col ++ "\nLIMIT 100;\n")



-- PRIVATE


formatTable : TableId -> String
formatTable ( schema, table ) =
    if schema == "" then
        table

    else
        schema ++ "." ++ table


formatColumn : ColumnPath -> String
formatColumn column =
    -- FIXME: handle JSON columns
    column.head
