module DataSources.AmlMiner.AmlGenerator exposing (generate, relation)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Libs.String as String
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Index exposing (Index)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation exposing (Relation)
import Models.Project.Schema exposing (Schema)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.Unique exposing (Unique)


generate : Schema -> String
generate source =
    let
        relations : Dict TableId (Dict ColumnName (List Relation))
        relations =
            source.relations
                |> List.groupBy (.id >> Tuple.first >> Tuple.first)
                |> Dict.map (\_ r -> r |> List.groupBy (.id >> Tuple.first >> Tuple.second))
    in
    source.tables |> Dict.values |> List.map (\t -> t |> generateTable (relations |> Dict.getOrElse ( t.schema, t.name ) Dict.empty)) |> String.join "\n\n"


generateTable : Dict ColumnName (List Relation) -> Table -> String
generateTable relations table =
    let
        columns : List String
        columns =
            table.columns
                |> Dict.values
                |> List.sortBy .index
                |> List.map (\c -> c |> generateColumn table.primaryKey table.uniques table.indexes table.checks (relations |> Dict.getOrElse c.name []))
    in
    generateTableName table
        ++ (table.comment |> Maybe.mapOrElse (\c -> " | " ++ c.text) "")
        ++ (columns |> List.map (String.prepend "\n  ") |> String.join "")


generateTableName : Table -> String
generateTableName table =
    generateTableId ( table.schema, table.name )


generateTableId : TableId -> String
generateTableId ( schema, table ) =
    if schema == "" then
        table

    else
        schema ++ "." ++ table


generateColumn : Maybe PrimaryKey -> List Unique -> List Index -> List Check -> List Relation -> Column -> String
generateColumn pk uniques indexes checks relations column =
    column.name
        ++ " "
        ++ column.kind
        ++ (column.default |> Maybe.mapOrElse (\d -> "=" ++ d) "")
        ++ (if column.nullable then
                " nullable"

            else if pk |> Maybe.any (\k -> k.columns |> Nel.any (\p -> p.head == column.name)) then
                " pk"

            else
                ""
           )
        ++ (uniques
                |> List.find (\u -> u.columns |> Nel.any (\c -> c.head == column.name))
                |> Maybe.mapOrElse (\u -> " unique" ++ (u.columns.tail |> List.head |> Maybe.mapOrElse (\_ -> "=" ++ u.name) "")) ""
           )
        ++ (indexes
                |> List.find (\i -> i.columns |> Nel.any (\c -> c.head == column.name))
                |> Maybe.mapOrElse (\i -> " index" ++ (i.columns.tail |> List.head |> Maybe.mapOrElse (\_ -> "=" ++ i.name) "")) ""
           )
        ++ (checks
                |> List.find (\c -> List.map .head c.columns == [ column.name ])
                |> Maybe.mapOrElse (\c -> " check" ++ (c.predicate |> Maybe.mapOrElse (\p -> "=\"" ++ p ++ "\"") "")) ""
           )
        ++ (relations |> List.head |> Maybe.mapOrElse (\r -> " fk " ++ generateTableId r.ref.table ++ "." ++ r.ref.column.head) "")
        ++ (column.comment |> Maybe.mapOrElse (\c -> " | " ++ c.text) "")


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
