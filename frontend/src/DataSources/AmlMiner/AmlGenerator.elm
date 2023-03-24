module DataSources.AmlMiner.AmlGenerator exposing (generate, relation)

import Dict exposing (Dict)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)


generate : { s | tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType } -> String
generate _ =
    ""


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
