module DataSources.AmlMiner.AmlGenerator exposing (relation)

import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)


relation : ColumnRef -> ColumnRef -> String
relation src ref =
    "fk " ++ columnRef src ++ " -> " ++ columnRef ref


columnRef : ColumnRef -> String
columnRef { table, column } =
    tableId table ++ "." ++ (column |> ColumnPath.toString |> quotesWhenNeeded)


tableId : TableId -> String
tableId ( schema, table ) =
    if schema == "" then
        table |> quotesWhenNeeded

    else
        (schema |> quotesWhenNeeded) ++ "." ++ (table |> quotesWhenNeeded)


quotesWhenNeeded : String -> String
quotesWhenNeeded name =
    if name |> String.contains " " then
        "\"" ++ name ++ "\""

    else
        name
