module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.ProPlan as ProPlan
import Conf
import DataSources.DbMiner.DbQuery as DbQuery
import Dict exposing (Dict)
import Html exposing (Html, div, h3, h4, h5, p, span, text)
import Html.Attributes exposing (class, classList, id)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw exposing (sm)
import Libs.Url exposing (UrlPath)
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.Organization exposing (Organization)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef, ColumnRefLike)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceIdStr)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import Models.SqlScript exposing (SqlScript)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), SchemaAnalysisDialog, SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.SuggestedRelation as SuggestedRelation exposing (SuggestedRelation, SuggestedRelationFound)
import Ports
import Services.Analysis.MissingRelations as MissingRelations
import Services.Backend as Backend



{-
   Improve analysis:
    - '_at' columns not of date type
    - '_ids' columns not of array type (ex: profiles.additional_organization_ids)
    - % of nullable columns in a table (warn if > 50%)
    - ?identify PII

   https://schemaspy.org/sample/anomalies.html
   - Tables that contain a single column
   - Tables without indexes
   - Columns whose default value is the word 'NULL' or 'null'
   - Tables with incrementing column names, potentially indicating denormalization

   https://www.databasestar.com/database-design-mistakes
-}


viewSchemaAnalysis : UrlPath -> ProjectRef -> Bool -> SchemaName -> List Source -> Dict TableId ErdTable -> List ErdRelation -> Dict TableId (List ColumnPath) -> SchemaAnalysisDialog -> Html Msg
viewSchemaAnalysis basePath project opened defaultSchema sources tables relations ignoredRelations model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal { id = model.id, titleId = titleId, isOpen = opened, onBackgroundClick = ModalClose (SchemaAnalysisMsg SAClose) }
        [ viewHeader titleId
        , if project.organization.plan.dbAnalysis then
            div [] []

          else
            div [ class "max-w-5xl px-6 mt-3" ] [ ProPlan.analysisWarning basePath project ]
        , viewAnalysis basePath project model.opened defaultSchema sources tables relations ignoredRelations
        , viewFooter
        ]


viewHeader : HtmlId -> Html msg
viewHeader titleId =
    div [ css [ "max-w-5xl px-6 mt-3", sm [ "flex items-start" ] ] ]
        [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
            [ Icon.outline Beaker "text-primary-600"
            ]
        , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Schema analysis" ]
            , p [ class "text-sm text-gray-500" ]
                [ text "Let's find out if you can make improvements on your schema..." ]
            ]
        ]


viewAnalysis : UrlPath -> ProjectRef -> HtmlId -> SchemaName -> List Source -> Dict TableId ErdTable -> List ErdRelation -> Dict TableId (List ColumnPath) -> Html Msg
viewAnalysis basePath project opened defaultSchema sources erdTables erdRelations ignoredRelations =
    let
        tables : Dict TableId Table
        tables =
            erdTables |> Dict.map (\_ -> ErdTable.unpack)

        relations : List Relation
        relations =
            erdRelations |> List.map ErdRelation.unpack
    in
    div [ class "max-w-5xl px-6 mt-3" ]
        [ viewMissingPrimaryKey basePath "missing-pks" project opened defaultSchema (computeMissingPrimaryKey erdTables)
        , viewMissingRelations basePath "missing-relations" project opened defaultSchema (MissingRelations.forTables tables relations ignoredRelations |> Dict.values |> List.concatMap Dict.values |> List.concatMap identity)
        , viewRelationsWithDifferentTypes basePath "relations-with-different-types" project opened defaultSchema sources (computeRelationsWithDifferentTypes defaultSchema erdTables erdRelations)
        , viewHeterogeneousTypes basePath "heterogeneous-types" project opened defaultSchema (computeHeterogeneousTypes erdTables)
        , viewBigTables basePath "big-tables" project opened defaultSchema (computeBigTables erdTables)
        ]


viewFooter : Html Msg
viewFooter =
    div [ class "max-w-5xl px-6 mt-3 py-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ Button.primary3 Tw.primary [ class "ml-3", onClick (ModalClose (SchemaAnalysisMsg SAClose)) ] [ text "Close" ]
        , span [] [ text "If you've got any ideas for improvements, ", extLink "https://github.com/azimuttapp/azimutt/discussions/75" [ class "link" ] [ text "please let us know" ], text "." ]
        ]



-- MISSING PRIMARY KEY


computeMissingPrimaryKey : Dict TableId ErdTable -> List ErdTable
computeMissingPrimaryKey tables =
    tables |> Dict.values |> List.filter (\t -> t.primaryKey == Nothing)


viewMissingPrimaryKey : UrlPath -> HtmlId -> ProjectRef -> HtmlId -> SchemaName -> List ErdTable -> Html Msg
viewMissingPrimaryKey basePath htmlId project opened defaultSchema missingPks =
    viewSection htmlId
        opened
        "All tables have a primary key"
        (missingPks |> List.length)
        (\nb -> "Found " ++ (nb |> String.pluralize "table") ++ " without a primary key")
        [ p [ class "mb-3 text-sm text-gray-500" ] [ text "It's not always required to have a primary key but strongly encouraged in most case. Make sure this is what you want!" ]
        , ProPlan.analysisResults basePath
            project
            missingPks
            (\t ->
                div [ class "flex justify-between items-center my-1" ]
                    [ div [] [ bText (TableId.show defaultSchema t.id), text " has no primary key" ]
                    , Button.primary1 Tw.primary [ class "ml-3", onClick (ShowTable t.id Nothing) ] [ text "Show table" ]
                    ]
            )
        ]



-- MISSING RELATIONS


viewMissingRelations : UrlPath -> HtmlId -> ProjectRef -> HtmlId -> SchemaName -> List SuggestedRelation -> Html Msg
viewMissingRelations basePath htmlId project opened defaultSchema suggestedRels =
    let
        ( relsNoRef, relsWithRef ) =
            suggestedRels |> List.partition (\r -> r.ref == Nothing)

        sortedMissingRels : List SuggestedRelationFound
        sortedMissingRels =
            relsWithRef |> List.filterMap SuggestedRelation.toFound |> List.sortBy (SuggestedRelation.toRefs >> (\r -> ColumnRef.show defaultSchema r.ref ++ " ← " ++ ColumnRef.show defaultSchema r.src))
    in
    viewSection htmlId
        opened
        "No potentially missing relation found"
        (suggestedRels |> List.length)
        (\nb -> "Found " ++ (nb |> String.pluralize "potentially missing relation"))
        [ if List.nonEmpty relsWithRef && project.organization.plan.dbAnalysis then
            div []
                [ Button.primary1 Tw.primary
                    [ onClick (sortedMissingRels |> List.map SuggestedRelation.toRefs |> CreateRelations) ]
                    [ text ("Add all " ++ String.pluralizeL "relation" sortedMissingRels) ]
                ]

          else
            div [] []
        , ProPlan.analysisResults basePath
            project
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
                        , Button.primary1 Tw.primary [ onClick (CreateRelations [ SuggestedRelation.toRefs rel ]) ] [ text "Add" ]
                        , Button.white1 Tw.red [ onClick (IgnoreRelation { table = rel.src.table, column = rel.src.column }), class "ml-1" ] [ text "Ignore" ]
                        ]
                    ]
            )
        , if relsNoRef |> List.isEmpty then
            div [] []

          else
            div []
                [ h5 [ class "mt-1 font-medium" ] [ text "Some columns may need a relation, but can't find a related table:" ]
                , ProPlan.analysisResults basePath
                    project
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



-- RELATIONS WITH DIFFERENT TYPES


computeRelationsWithDifferentTypes : SchemaName -> Dict TableId ErdTable -> List ErdRelation -> List ( ErdRelation, ErdColumn, ErdColumn )
computeRelationsWithDifferentTypes defaultSchema tables relations =
    let
        getColumn : ColumnRefLike x -> Maybe ErdColumn
        getColumn ref =
            tables |> ErdTable.getTable defaultSchema ref.table |> Maybe.andThen (ErdTable.getColumn ref.column)
    in
    relations
        |> List.filterMap (\r -> Maybe.map2 (\src ref -> ( r, src, ref )) (getColumn r.src) (getColumn r.ref))
        |> List.filter (\( _, src, ref ) -> src.kind /= ref.kind)


viewRelationsWithDifferentTypes : UrlPath -> HtmlId -> ProjectRef -> HtmlId -> SchemaName -> List Source -> List ( ErdRelation, ErdColumn, ErdColumn ) -> Html Msg
viewRelationsWithDifferentTypes basePath htmlId project opened defaultSchema sources badRels =
    viewSection htmlId
        opened
        "No relation with different types found"
        (badRels |> List.length)
        (\nb -> "Found " ++ (nb |> String.pluralize "relation") ++ " with different types")
        [ if List.nonEmpty badRels && project.organization.plan.dbAnalysis then
            div []
                [ Button.primary1 Tw.primary
                    [ onClick (badRels |> scriptForRelationsWithDifferentTypes defaultSchema sources |> Ports.downloadFile "azimutt-fix-relations-with-different-types.sql" |> Send) ]
                    [ text "Download SQL script to fix all" ]
                ]

          else
            div [] []
        , ProPlan.analysisResults basePath
            project
            (badRels |> List.sortBy (\( rel, _, _ ) -> ColumnRef.show defaultSchema rel.ref ++ " ← " ++ ColumnRef.show defaultSchema rel.src))
            (\( rel, src, ref ) ->
                div [ class "flex justify-between items-center py-1" ]
                    [ div []
                        [ text (TableId.show defaultSchema rel.ref.table)
                        , span [ class "text-gray-500" ] [ text ("" |> ColumnPath.withName rel.ref.column) ]
                        , Icon.solid ArrowNarrowLeft "inline mx-1"
                        , text (TableId.show defaultSchema rel.src.table)
                        , span [ class "text-gray-500" ] [ text ("" |> ColumnPath.withName rel.src.column) ]
                        ]
                    , div [ class "ml-3 text-gray-400" ] [ Icon.solid Exclamation "inline", text (" " ++ ref.kind ++ " vs " ++ src.kind) ]
                    ]
            )
        ]


scriptForRelationsWithDifferentTypes : SchemaName -> List Source -> List ( ErdRelation, ErdColumn, ErdColumn ) -> SqlScript
scriptForRelationsWithDifferentTypes defaultSchema sources relations =
    let
        sourcesById : Dict SourceIdStr Source
        sourcesById =
            sources |> List.groupBy (.id >> SourceId.toString) |> Dict.filterMap (\_ -> List.head)

        defaultSource : Maybe DbSourceInfo
        defaultSource =
            sources |> List.findMap DbSourceInfo.fromSource
    in
    "-- Script generated by Azimutt\n"
        ++ "-- Queries to fix column types for relations with different types (apply primary key column type to foreign key column)\n\n"
        ++ (relations
                |> List.sortBy (\( rel, _, _ ) -> ColumnRef.show defaultSchema rel.ref ++ " ← " ++ ColumnRef.show defaultSchema rel.src)
                |> List.concatMap (\( rel, src, ref ) -> src.origins |> List.map (\o -> { source = SourceId.toString o.id, relation = ( rel, ref ) }))
                |> List.groupBy .source
                |> Dict.toList
                |> List.map (\( sourceId, rels ) -> scriptForSource defaultSource (sourcesById |> Dict.get sourceId) (rels |> List.map .relation))
                |> String.join "\n\n\n"
           )
        ++ "\n"


scriptForSource : Maybe DbSourceInfo -> Maybe Source -> List ( ErdRelation, ErdColumn ) -> SqlScript
scriptForSource defaultSource source relations =
    let
        name : String
        name =
            source |> Maybe.mapOrElse .name "unknown"

        kind : DatabaseKind
        kind =
            source
                |> Maybe.andThen Source.databaseUrl
                |> Maybe.map DatabaseKind.fromUrl
                |> Maybe.orElse (defaultSource |> Maybe.map (.db >> .kind))
                |> Maybe.withDefault DatabaseKind.PostgreSQL
    in
    ("-- Queries for " ++ name ++ " source\n")
        ++ (relations
                |> List.map (\( rel, ref ) -> DbQuery.updateColumnType kind rel.src ref.kind |> .sql)
                |> List.filter (\q -> q /= "")
                |> String.join "\n"
           )



-- HETEROGENEOUS TYPES


computeHeterogeneousTypes : Dict TableId ErdTable -> List ( ColumnName, List ( ColumnType, List TableId ) )
computeHeterogeneousTypes tables =
    tables
        |> Dict.values
        |> List.concatMap (\t -> t.columns |> Dict.values |> List.filter (\c -> c.kind /= Conf.schema.column.unknownType) |> List.map (\c -> { table = t.id, column = c.path |> ColumnPath.toString, kind = c.kind }))
        |> List.groupBy .column
        |> Dict.toList
        |> List.map (\( col, cols ) -> ( col, cols |> List.groupBy .kind |> Dict.map (\_ -> List.map .table) |> Dict.toList ))
        |> List.filter (\( _, cols ) -> (cols |> List.length) > 1)


viewHeterogeneousTypes : UrlPath -> HtmlId -> ProjectRef -> HtmlId -> SchemaName -> List ( ColumnName, List ( ColumnType, List TableId ) ) -> Html Msg
viewHeterogeneousTypes basePath htmlId project opened defaultSchema heterogeneousTypes =
    viewSection htmlId
        opened
        "No heterogeneous types found"
        (heterogeneousTypes |> List.length)
        (\nb -> "Found " ++ (nb |> String.pluralize "column") ++ " with heterogeneous types")
        [ p [ class "mb-1 text-sm text-gray-500" ]
            [ text
                ("There is nothing wrong intrinsically with heterogeneous types "
                    ++ "but sometimes, the same concept stored in different format may not be ideal and having everything aligned is clearer. "
                    ++ "But of course, not every column with the same name is the same thing, so just look at the to know, not to fix everything."
                )
            ]
        , ProPlan.analysisResults basePath
            project
            heterogeneousTypes
            (\( col, types ) ->
                div []
                    [ bText col
                    , text " has types: "
                    , span [ class "text-gray-500" ]
                        (types
                            |> List.map (\( t, ids ) -> text t |> Tooltip.t (ids |> List.map (TableId.show defaultSchema) |> String.join ", "))
                            |> List.intersperse (text ", ")
                        )
                    ]
            )
        ]



-- BIG TABLES


computeBigTables : Dict TableId ErdTable -> List ErdTable
computeBigTables tables =
    tables
        |> Dict.values
        |> List.filter (\t -> (t.columns |> Dict.size) > 30)
        |> List.sortBy (\t -> t.columns |> Dict.size |> negate)


viewBigTables : UrlPath -> HtmlId -> ProjectRef -> HtmlId -> SchemaName -> List ErdTable -> Html Msg
viewBigTables basePath htmlId project opened defaultSchema bigTables =
    viewSection htmlId
        opened
        "No big table found"
        (bigTables |> List.length)
        (\nb -> "Found " ++ (nb |> String.pluralize "table") ++ " too big")
        [ div [ class "mb-1 text-gray-500" ]
            [ text "See "
            , extLink (Backend.blogArticleUrl basePath "why-you-should-avoid-tables-with-many-columns-and-how-to-fix-them")
                [ css [ "link" ] ]
                [ text "Why you should avoid tables with many columns, and how to fix them"
                ]
            ]
        , ProPlan.analysisResults basePath project bigTables (\t -> div [] [ text ((t.columns |> Dict.size |> String.pluralize "column") ++ ": "), bText (TableId.show defaultSchema t.id) ])
        ]



-- HELPERS


viewSection : HtmlId -> HtmlId -> String -> Int -> (Int -> String) -> List (Html Msg) -> Html Msg
viewSection htmlId opened successTitle errorCount failureTitle content =
    let
        isOpen : Bool
        isOpen =
            opened == htmlId
    in
    if errorCount == 0 then
        div [ class "mt-3" ]
            [ h4 [ class "leading-5 font-medium" ]
                [ Icon.solid Check "inline mr-3 text-green-500"
                , text successTitle
                ]
            ]

    else
        div [ class "mt-3" ]
            [ h4 [ class "mb-1 leading-5 font-medium cursor-pointer", onClick (SchemaAnalysisMsg (SASectionToggle htmlId)) ]
                [ Icon.solid LightBulb "inline mr-3 text-yellow-500"
                , text (errorCount |> failureTitle)
                , Icon.solid ChevronDown ("inline transform transition " ++ B.cond isOpen "-rotate-180" "")
                ]
            , div [ class "ml-8", classList [ ( "hidden", not isOpen ) ] ] content
            ]
