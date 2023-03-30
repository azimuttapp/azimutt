module DataSources.SqlMiner.PostgreSqlGenerator exposing (generate)

import DataSources.SqlMiner.SqlGenerator exposing (organizeTablesAndRelations)
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Libs.String as String
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation exposing (Relation)
import Models.Project.Schema exposing (Schema)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.Unique exposing (Unique)


generate : Schema -> String
generate schema =
    let
        ( tables, relations, lazyRelation ) =
            organizeTablesAndRelations schema
    in
    tables |> List.map (\t -> t |> generateTable (relations |> Dict.getOrElse t.id Dict.empty) (lazyRelation |> Dict.getOrElse t.id [])) |> String.join "\n\n"


generateTable : Dict ColumnName (List Relation) -> List Relation -> Table -> String
generateTable relations lazyRelation table =
    let
        columns : List String
        columns =
            table.columns
                |> Dict.values
                |> List.sortBy .index
                |> List.map (\c -> c |> generateColumn table.primaryKey table.uniques table.checks (relations |> Dict.getOrElse c.name []))

        primaryKey : List String
        primaryKey =
            table.primaryKey
                |> Maybe.toList
                |> List.filterNot (\k -> List.isEmpty k.columns.tail)
                |> List.map (\k -> "PRIMARY KEY (" ++ (k.columns |> Nel.toList |> List.map .head |> String.join ", ") ++ ")")

        uniques : List String
        uniques =
            table.uniques
                |> List.filterNot (\u -> List.isEmpty u.columns.tail)
                |> List.map (\u -> "UNIQUE (" ++ (u.columns |> Nel.toList |> List.map .head |> String.join ", ") ++ ")")
    in
    ("CREATE TABLE " ++ generateTableName table ++ " (")
        ++ ((columns ++ primaryKey ++ uniques) |> List.map (String.prepend "\n  ") |> String.join ",")
        ++ "\n);"
        ++ (table.indexes |> List.map (generateIndex table >> String.prepend "\n") |> String.join "")
        ++ (table.comment |> Maybe.mapOrElse (generateTableComment table >> String.prepend "\n") "")
        ++ (lazyRelation |> List.map (generateLazyForeignKey >> String.prepend "\n") |> String.join "")


generateTableName : Table -> String
generateTableName table =
    generateTableId ( table.schema, table.name )


generateTableId : TableId -> String
generateTableId ( schema, table ) =
    if schema == "" then
        table

    else
        schema ++ "." ++ table


generateColumn : Maybe PrimaryKey -> List Unique -> List Check -> List Relation -> Column -> String
generateColumn pk uniques checks relations column =
    column.name
        ++ " "
        ++ column.kind
        ++ (if column.nullable then
                ""

            else if pk |> Maybe.any (\k -> k.columns |> Nel.any (\p -> p.head == column.name)) then
                if pk |> Maybe.any (\k -> k.columns.tail |> List.isEmpty) then
                    " PRIMARY KEY"

                else
                    ""

            else
                " NOT NULL"
           )
        ++ (uniques
                |> List.find (\u -> u.columns.head.head == column.name && List.isEmpty u.columns.tail)
                |> Maybe.mapOrElse (\_ -> " UNIQUE") ""
           )
        ++ (checks
                |> List.find (\c -> List.map .head c.columns == [ column.name ])
                |> Maybe.mapOrElse (\c -> " CHECK" ++ (c.predicate |> Maybe.mapOrElse (\p -> " (" ++ p ++ ")") "")) ""
           )
        ++ (relations |> List.head |> Maybe.mapOrElse (\r -> " REFERENCES " ++ generateTableId r.ref.table ++ "(" ++ r.ref.column.head ++ ")") "")
        ++ (column.default
                |> Maybe.mapOrElse
                    (\d ->
                        " DEFAULT "
                            ++ (if isStringType column.kind then
                                    "\"" ++ d ++ "\""

                                else
                                    d
                               )
                    )
                    ""
           )
        ++ (column.comment |> Maybe.mapOrElse (\c -> " COMMENT \"" ++ c.text ++ "\"") "")


isStringType : ColumnType -> Bool
isStringType kind =
    (kind |> String.startsWith "varchar") || (kind |> String.startsWith "text")


generateIndex : Table -> Index -> String
generateIndex table index =
    "CREATE INDEX " ++ index.name ++ " ON " ++ generateTableName table ++ " (" ++ (index.columns |> Nel.toList |> List.map .head |> String.join ", ") ++ ");"


generateTableComment : Table -> Comment -> String
generateTableComment table comment =
    "COMMENT ON TABLE " ++ generateTableName table ++ " IS \"" ++ (comment.text |> String.replace "\"" "\\\"") ++ "\";"


generateLazyForeignKey : Relation -> String
generateLazyForeignKey relation =
    "ALTER TABLE " ++ generateTableId relation.src.table ++ " ADD CONSTRAINT " ++ relation.name ++ " FOREIGN KEY (" ++ relation.src.column.head ++ ") REFERENCES " ++ generateTableId relation.ref.table ++ "(" ++ relation.ref.column.head ++ ");"
