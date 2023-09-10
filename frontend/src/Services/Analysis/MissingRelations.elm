module Services.Analysis.MissingRelations exposing (forTables)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Libs.String as String
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.SuggestedRelation exposing (SuggestedRelation, SuggestedRelationRef)


forTables : Dict TableId Table -> List Relation -> Dict TableId (List ColumnPath) -> Dict TableId (Dict ColumnPathStr (List SuggestedRelation))
forTables tables relations ignoredRelations =
    let
        tableNames : Dict NormalizedTableName (List TableId)
        tableNames =
            tables |> Dict.keys |> List.groupBy (\( _, tableName ) -> tableName |> String.splitWords |> String.join "_")

        relationBySrc : Dict TableId (Dict ColumnPathStr (List Relation))
        relationBySrc =
            relations |> List.groupBy (.src >> .table) |> Dict.map (\_ -> List.groupBy (.src >> .column >> ColumnPath.toString))
    in
    tables
        |> Dict.map
            (\_ table ->
                let
                    ignoreColumns : List ColumnPath
                    ignoreColumns =
                        ignoredRelations |> Dict.getOrElse table.id []
                in
                table.columns
                    |> Dict.values
                    |> List.concatMap Column.flatten
                    |> List.filterNot (\c -> ignoreColumns |> List.member c.path)
                    |> List.map (\c -> ( c.path |> ColumnPath.toString, find tableNames tables relationBySrc table c ))
                    |> List.filter (Tuple.second >> List.nonEmpty)
                    |> Dict.fromList
            )
        |> Dict.filter (\_ -> Dict.nonEmpty)


type alias NormalizedTableName =
    -- tableName |> StringCase.splitWords |> String.join "_"
    String


find : Dict NormalizedTableName (List TableId) -> Dict TableId Table -> Dict TableId (Dict ColumnPathStr (List Relation)) -> Table -> { path : ColumnPath, column : Column } -> List SuggestedRelation
find tableNames tables relationBySrc table { path, column } =
    let
        columnWords : List String
        columnWords =
            column.name |> String.splitWords

        targetColumnName : ColumnName
        targetColumnName =
            columnWords |> List.last |> Maybe.withDefault column.name |> String.singular

        relations : List Relation
        relations =
            relationBySrc |> Dict.get table.id |> Maybe.andThen (Dict.get (ColumnPath.toString path)) |> Maybe.withDefault []
    in
    if targetColumnName == "id" && List.length columnWords > 1 then
        let
            colRef : SuggestedRelationRef
            colRef =
                { table = table.id, column = path, kind = column.kind }

            tableHint : List String
            tableHint =
                columnWords |> List.dropRight 1

            suggestedRelations : List SuggestedRelation
            suggestedRelations =
                getTypeColumn table path
                    |> Maybe.andThen
                        (\typeCol ->
                            typeCol.column.values
                                |> Maybe.map
                                    (Nel.toList
                                        >> List.map
                                            (\value ->
                                                { src = colRef
                                                , ref = getTargetColumn tableNames tables table.schema (value |> String.splitWords) targetColumnName
                                                , when = Just { column = typeCol.path, value = value }
                                                }
                                            )
                                        >> List.filter (\rel -> rel.ref /= Nothing)
                                    )
                        )
                    |> Maybe.withDefault [ { src = colRef, ref = getTargetColumn tableNames tables table.schema tableHint targetColumnName, when = Nothing } ]
        in
        -- remove existing relations
        suggestedRelations
            |> List.filter
                (\sr ->
                    sr.ref
                        |> Maybe.map (\r -> { table = r.table, column = r.column })
                        |> Maybe.map (\ref -> relations |> List.any (\r -> r.ref == ref) |> not)
                        |> Maybe.withDefault (relations |> List.isEmpty)
                )

    else
        []


getTypeColumn : Table -> ColumnPath -> Maybe { path : ColumnPath, column : Column }
getTypeColumn table path =
    -- useful for polymorphic relations
    let
        typePath : ColumnPath
        typePath =
            path
                |> Nel.mapLast
                    (\name ->
                        if name |> String.endsWith "id" then
                            String.dropRight 2 name ++ "type"

                        else if name |> String.endsWith "ids" then
                            String.dropRight 3 name ++ "type"

                        else if name |> String.endsWith "Id" then
                            String.dropRight 2 name ++ "Type"

                        else if name |> String.endsWith "Ids" then
                            String.dropRight 3 name ++ "Type"

                        else if name |> String.endsWith "ID" then
                            String.dropRight 2 name ++ "TYPE"

                        else if name |> String.endsWith "IDS" then
                            String.dropRight 3 name ++ "TYPE"

                        else
                            name ++ "_type"
                    )
    in
    table |> Table.getColumn typePath |> Maybe.map (\c -> { path = typePath, column = c })


getTargetColumn : Dict NormalizedTableName (List TableId) -> Dict TableId Table -> SchemaName -> List String -> ColumnName -> Maybe SuggestedRelationRef
getTargetColumn tableNames tables preferredSchema tableHint targetColumnName =
    (tableHint |> String.join "_" |> getTable tableNames tables preferredSchema targetColumnName)
        |> Maybe.onNothing (\_ -> tableHint |> String.join "_" |> String.plural |> getTable tableNames tables preferredSchema targetColumnName)
        |> Maybe.onNothing (\_ -> tableHint |> List.drop 1 |> String.join "_" |> getTable tableNames tables preferredSchema targetColumnName)
        |> Maybe.onNothing (\_ -> tableHint |> List.drop 1 |> String.join "_" |> String.plural |> getTable tableNames tables preferredSchema targetColumnName)


getTable : Dict NormalizedTableName (List TableId) -> Dict TableId Table -> SchemaName -> ColumnName -> NormalizedTableName -> Maybe SuggestedRelationRef
getTable tableNames tables preferredSchema columnName tableName =
    (tableNames |> Dict.get tableName)
        |> Maybe.andThen (\ids -> ids |> List.find (\( schema, _ ) -> schema == preferredSchema) |> Maybe.orElse (ids |> List.head))
        |> Maybe.andThen (\id -> tables |> Dict.get id)
        |> Maybe.andThen (\table -> table.columns |> Dict.get columnName |> Maybe.map (\col -> { table = table.id, column = Nel columnName [], kind = col.kind }))
