module DataSources.AmlMiner.AmlGenerator exposing (relationStandalone)

import Libs.Nel as Nel
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)


relationStandalone : ColumnRef -> ColumnRef -> String
relationStandalone src ref =
    -- MUST stay sync with AML syntax, and more specifically libs/aml/src/amlGenerator.ts:108 (genRelation)
    "rel " ++ columnRef src ++ " -> " ++ columnRef ref


columnRef : ColumnRef -> String
columnRef { table, column } =
    tableRef table ++ "(" ++ columnPath column ++ ")"


tableRef : TableId -> String
tableRef ( schema, table ) =
    if schema == "" then
        table |> quotesWhenNeeded

    else
        (schema |> quotesWhenNeeded) ++ "." ++ (table |> quotesWhenNeeded)


columnPath : ColumnPath -> String
columnPath column =
    column |> Nel.map quotesWhenNeeded |> Nel.join "."


quotesWhenNeeded : String -> String
quotesWhenNeeded name =
    if name |> String.contains " " then
        "\"" ++ name ++ "\""

    else
        name
