module Services.Analysis.MissingRelations exposing (SuggestedRelation, SuggestedRelationFound, SuggestedRelationRef, forTables, toFound, toRefs)

import Dict exposing (Dict)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Libs.String as String
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.ErdColumn as ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)


type alias SuggestedRelation =
    { src : SuggestedRelationRef, ref : Maybe SuggestedRelationRef, when : Maybe { column : ErdColumn, value : String } }


type alias SuggestedRelationRef =
    { table : ErdTable, column : ErdColumn }


forTables : Dict TableId ErdTable -> List SuggestedRelation
forTables tables =
    let
        tableNames : Dict NormalizedTableName (List TableId)
        tableNames =
            tables |> Dict.keys |> List.groupBy (\( _, tableName ) -> tableName |> String.splitWords |> String.join "_")
    in
    tables |> Dict.values |> List.concatMap (\table -> table.columns |> Dict.values |> List.concatMap ErdColumn.flatten |> List.concatMap (find tableNames tables table))



{-
   forTable : Dict TableId ErdTable -> ErdTable -> List SuggestedRelation
   forTable tables table =
       let
           tableNames : Dict NormalizedTableName (List TableId)
           tableNames =
               tables |> Dict.keys |> List.groupBy (\( _, tableName ) -> tableName |> String.splitWords |> String.join "_")
       in
       table.columns |> Dict.values |> List.concatMap ErdColumn.flatten |> List.concatMap (find tableNames tables table)
-}


type alias SuggestedRelationFound =
    { src : SuggestedRelationRef, ref : SuggestedRelationRef, when : Maybe { column : ErdColumn, value : String } }


toFound : SuggestedRelation -> Maybe SuggestedRelationFound
toFound rel =
    rel.ref |> Maybe.map (\ref -> { src = rel.src, ref = ref, when = rel.when })


toRefs : SuggestedRelationFound -> { src : ColumnRef, ref : ColumnRef }
toRefs rel =
    { src = { table = rel.src.table.id, column = rel.src.column.path }, ref = { table = rel.ref.table.id, column = rel.ref.column.path } }


find : Dict NormalizedTableName (List TableId) -> Dict TableId ErdTable -> ErdTable -> ErdColumn -> List SuggestedRelation
find tableNames tables table column =
    let
        columnWords : List String
        columnWords =
            column.name |> String.splitWords

        targetColumnName : ColumnName
        targetColumnName =
            columnWords |> List.last |> Maybe.withDefault column.name |> String.singular
    in
    if targetColumnName == "id" && List.length columnWords > 1 && List.isEmpty column.inRelations && List.isEmpty column.outRelations then
        let
            colRef : SuggestedRelationRef
            colRef =
                { table = table, column = column }

            tableHint : List String
            tableHint =
                columnWords |> List.dropRight 1

            suggestedRelations : List SuggestedRelation
            suggestedRelations =
                getTypeColumn table column
                    |> Maybe.andThen
                        (\typeCol ->
                            typeCol.values
                                |> Maybe.map
                                    (Nel.toList
                                        >> List.map
                                            (\value ->
                                                { src = colRef
                                                , ref = getTargetColumn tableNames tables table.schema (value |> String.splitWords) targetColumnName
                                                , when = Just { column = typeCol, value = value }
                                                }
                                            )
                                        >> List.filter (\rel -> rel.ref /= Nothing)
                                    )
                        )
                    |> Maybe.withDefault [ { src = colRef, ref = getTargetColumn tableNames tables table.schema tableHint targetColumnName, when = Nothing } ]
        in
        suggestedRelations

    else
        []


getTypeColumn : ErdTable -> ErdColumn -> Maybe ErdColumn
getTypeColumn table column =
    -- useful for polymorphic relations
    let
        path : ColumnPath
        path =
            column.path
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
    table |> ErdTable.getColumn path


type alias NormalizedTableName =
    -- tableName |> StringCase.splitWords |> String.join "_"
    String


getTargetColumn : Dict NormalizedTableName (List TableId) -> Dict TableId ErdTable -> SchemaName -> List String -> ColumnName -> Maybe SuggestedRelationRef
getTargetColumn tableNames tables preferredSchema tableHint targetColumnName =
    (tableHint |> String.join "_" |> getTable tableNames tables preferredSchema targetColumnName)
        |> Maybe.onNothing (\_ -> tableHint |> String.join "_" |> String.plural |> getTable tableNames tables preferredSchema targetColumnName)
        |> Maybe.onNothing (\_ -> tableHint |> List.drop 1 |> String.join "_" |> getTable tableNames tables preferredSchema targetColumnName)
        |> Maybe.onNothing (\_ -> tableHint |> List.drop 1 |> String.join "_" |> String.plural |> getTable tableNames tables preferredSchema targetColumnName)


getTable : Dict NormalizedTableName (List TableId) -> Dict TableId ErdTable -> SchemaName -> ColumnName -> NormalizedTableName -> Maybe SuggestedRelationRef
getTable tableNames tables preferredSchema columnName tableName =
    (tableNames |> Dict.get tableName)
        |> Maybe.andThen (\ids -> ids |> List.find (\( schema, _ ) -> schema == preferredSchema) |> Maybe.orElse (ids |> List.head))
        |> Maybe.andThen (\id -> tables |> Dict.get id)
        |> Maybe.andThen (\table -> table.columns |> Dict.get columnName |> Maybe.map (\col -> { table = table, column = col }))
