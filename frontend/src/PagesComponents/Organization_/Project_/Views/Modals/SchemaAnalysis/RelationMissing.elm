module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.RelationMissing exposing (Model, compute, heading, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.PlanDialog as PlanDialog
import Dict exposing (Dict)
import Html exposing (Html, div, h5, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Libs.String as String
import Libs.Tailwind as Tw
import Models.Organization as Organization
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models.SuggestedRelation as SuggestedRelation exposing (SuggestedRelation, SuggestedRelationFound, SuggestedRelationRef)


type alias Model =
    SuggestedRelation


compute : Dict TableId (List ColumnPath) -> Dict TableId Table -> List Relation -> List Model
compute ignoredRelations tables relations =
    -- same as libs/models/src/analyze/rules/relationMissing.ts
    let
        tableNames : Dict NormalizedTableName (List TableId)
        tableNames =
            tables |> Dict.keys |> List.groupBy (\( _, tableName ) -> tableName |> String.splitWords |> String.join "_")

        relationBySrc : Dict TableId (Dict ColumnPathStr (List Relation))
        relationBySrc =
            relations |> List.groupBy (.src >> .table) |> Dict.map (\_ -> List.groupBy (.src >> .column >> ColumnPath.toString))
    in
    tables
        |> Dict.values
        |> List.concatMap
            (\table ->
                let
                    ignoreColumns : List ColumnPath
                    ignoreColumns =
                        ignoredRelations |> Dict.getOrElse table.id []
                in
                table.columns
                    |> Dict.values
                    |> List.concatMap Column.flatten
                    |> List.filterNot (\c -> ignoreColumns |> List.member c.path)
                    |> List.concatMap (\c -> guessRelations tableNames tables relationBySrc table c)
            )


type alias NormalizedTableName =
    -- tableName |> StringCase.splitWords |> String.join "_"
    String


guessRelations : Dict NormalizedTableName (List TableId) -> Dict TableId Table -> Dict TableId (Dict ColumnPathStr (List Relation)) -> Table -> { path : ColumnPath, column : Column } -> List SuggestedRelation
guessRelations tableNames tables relationBySrc table { path, column } =
    let
        colRef : SuggestedRelationRef
        colRef =
            { table = table.id, column = path, kind = column.kind }

        colWords : List String
        colWords =
            column.name |> String.splitWords

        colLastWord : ColumnName
        colLastWord =
            colWords |> List.last |> Maybe.withDefault column.name |> String.singular
    in
    (if colLastWord == "id" && List.length colWords > 1 then
        let
            targetTableHint : List String
            targetTableHint =
                colWords |> List.dropRight 1

            suggestedRelations : List SuggestedRelation
            suggestedRelations =
                getPolymorphicColumn table path
                    |> Maybe.andThen
                        (\polymorphicCol ->
                            polymorphicCol.values
                                |> Maybe.map
                                    (Nel.toList
                                        >> List.map
                                            (\value ->
                                                { src = colRef
                                                , ref = getTargetColumn tableNames tables table.schema (value |> String.splitWords) colLastWord
                                                , when = Just { column = polymorphicCol.path, value = value }
                                                }
                                            )
                                        >> List.filter (\rel -> rel.ref /= Nothing)
                                    )
                        )
                    |> Maybe.withDefault [ { src = colRef, ref = getTargetColumn tableNames tables table.schema targetTableHint colLastWord, when = Nothing } ]
        in
        suggestedRelations

     else if String.endsWith "id" column.name && String.length column.name > 2 then
        -- when no separator before `id`
        let
            tableHint : List String
            tableHint =
                column.name |> String.dropRight 2 |> String.splitWords
        in
        [ { src = colRef, ref = [ column.name, "id" ] |> List.findMap (getTargetColumn tableNames tables table.schema tableHint), when = Nothing } ]

     else if List.last colWords == Just "by" then
        -- `created_by` columns should refer to a user like table
        [ { src = colRef, ref = [ [ "user" ], [ "account" ] ] |> List.findMap (\tableHint -> getTargetColumn tableNames tables table.schema tableHint "id"), when = Nothing } ]

     else
        []
    )
        |> removeKnownRelations relationBySrc table.id path


getPolymorphicColumn : Table -> ColumnPath -> Maybe { path : ColumnPath, values : Maybe (Nel String) }
getPolymorphicColumn table path =
    let
        ( suffixes, name ) =
            ( [ "type", "class", "kind" ], path |> ColumnPath.name )

        prefix : String
        prefix =
            if name |> String.toLower |> String.endsWith "ids" then
                name |> String.dropRight 3

            else if name |> String.toLower |> String.endsWith "id" then
                name |> String.dropRight 2

            else
                name
    in
    (table |> Table.getPeerColumns path)
        |> List.find (\c -> (c.name |> String.startsWith prefix) && (suffixes |> List.any (\s -> hasSuffix s c.name)))
        |> Maybe.map (\c -> { path = path |> Nel.mapLast (\_ -> c.name), values = c.values })


hasSuffix : String -> String -> Bool
hasSuffix suffix str =
    String.endsWith (String.toLower suffix) str || String.endsWith (String.toUpper suffix) str || String.endsWith (String.capitalize suffix) str


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


removeKnownRelations : Dict TableId (Dict ColumnPathStr (List Relation)) -> TableId -> ColumnPath -> List SuggestedRelation -> List SuggestedRelation
removeKnownRelations relationBySrc tableId columnPath suggestedRelations =
    let
        relations : List Relation
        relations =
            relationBySrc |> Dict.get tableId |> Maybe.andThen (Dict.get (ColumnPath.toString columnPath)) |> Maybe.withDefault []
    in
    suggestedRelations
        |> List.filter (\sr -> sr.ref /= Just sr.src)
        |> List.filter
            (\sr ->
                sr.ref
                    |> Maybe.map (\r -> { table = r.table, column = r.column })
                    |> Maybe.map (\ref -> relations |> List.any (\r -> r.ref == ref) |> not)
                    |> Maybe.withDefault (relations |> List.isEmpty)
            )


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "No potentially missing relation found"

                else
                    "Found " ++ (count |> String.pluralize "potentially missing relation")
           )


view : (List { src : ColumnRef, ref : ColumnRef } -> msg) -> (ColumnRef -> msg) -> ProjectRef -> SchemaName -> List Model -> Html msg
view createRelations ignoreRelation project defaultSchema errors =
    let
        ( relsNoRef, relsWithRef ) =
            errors |> List.partition (\r -> r.ref == Nothing)

        sortedMissingRels : List SuggestedRelationFound
        sortedMissingRels =
            relsWithRef |> List.filterMap SuggestedRelation.toFound |> List.sortBy (SuggestedRelation.toRefs >> (\r -> ColumnRef.show defaultSchema r.ref ++ " ← " ++ ColumnRef.show defaultSchema r.src))
    in
    div []
        [ if List.nonEmpty relsWithRef && Organization.canAnalyse project then
            div []
                [ Button.primary1 Tw.primary
                    [ onClick (sortedMissingRels |> List.map SuggestedRelation.toRefs |> createRelations) ]
                    [ text ("Add all " ++ String.pluralizeL "relation" sortedMissingRels) ]
                ]

          else
            div [] []
        , PlanDialog.analysisResults project
            sortedMissingRels
            (\rel ->
                div [ class "flex justify-between items-center py-1" ]
                    [ div []
                        [ text (TableId.show defaultSchema rel.ref.table)
                        , span [ class "text-gray-500" ] [ text ("" |> ColumnPath.withName rel.ref.column) ] |> Tooltip.t rel.ref.kind
                        , Icon.solid ArrowNarrowLeft "inline mx-1"
                        , text (TableId.show defaultSchema rel.src.table)
                        , span [ class "text-gray-500" ] [ text ("" |> ColumnPath.withName rel.src.column) ] |> Tooltip.t rel.src.kind
                        , rel.when
                            |> Maybe.map (\w -> span [] [ text " when ", span [ class "text-gray-400" ] [ text (ColumnPath.show w.column ++ "=" ++ w.value) ] ])
                            |> Maybe.withDefault (text "")
                        ]
                    , div [ class "ml-3" ]
                        [ B.cond (kindMatch rel) (span [] []) (span [ class "text-gray-400 mr-3" ] [ Icon.solid Exclamation "inline", text (" " ++ rel.ref.kind ++ " vs " ++ rel.src.kind) ])
                        , Button.primary1 Tw.primary [ onClick (createRelations [ SuggestedRelation.toRefs rel ]) ] [ text "Add" ]
                        , Button.white1 Tw.red [ onClick (ignoreRelation { table = rel.src.table, column = rel.src.column }), class "ml-1" ] [ text "Ignore" ]
                        ]
                    ]
            )
        , if relsNoRef |> List.isEmpty then
            div [] []

          else
            div []
                [ h5 [ class "mt-1 font-medium" ] [ text "Some columns may need a relation, but can't find a related table:" ]
                , PlanDialog.analysisResults project
                    relsNoRef
                    (\rel ->
                        div [ class "ml-3" ]
                            [ text (TableId.show defaultSchema rel.src.table)
                            , span [ class "text-gray-500" ] [ text ("" |> ColumnPath.withName rel.src.column) ] |> Tooltip.t rel.src.kind
                            ]
                    )
                ]
        ]


kindMatch : SuggestedRelationFound -> Bool
kindMatch rel =
    if (rel.src.column |> ColumnPath.toString |> String.toLower |> String.endsWith "_ids") && (rel.src.kind |> String.endsWith "[]") then
        (rel.src.kind |> String.dropRight 2) == rel.ref.kind

    else
        rel.src.kind == rel.ref.kind
