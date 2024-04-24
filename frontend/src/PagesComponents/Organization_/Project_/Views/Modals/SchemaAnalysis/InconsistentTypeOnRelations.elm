module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.InconsistentTypeOnRelations exposing (Model, compute, heading, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Slices.ProPlan as ProPlan
import DataSources.DbMiner.DbQuery as DbQuery
import Dict exposing (Dict)
import Html exposing (Html, div, p, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Libs.Dict as Dict
import Libs.Html exposing (bText)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.String as String
import Libs.Tailwind as Tw
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRefLike)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceIdStr)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import Models.SqlScript exposing (SqlScript)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import Ports


type alias Model =
    ( ErdRelation, ErdColumn, ErdColumn )


compute : SchemaName -> Dict TableId ErdTable -> List ErdRelation -> List Model
compute defaultSchema tables relations =
    let
        getColumn : ColumnRefLike x -> Maybe ErdColumn
        getColumn ref =
            tables |> ErdTable.getTable defaultSchema ref.table |> Maybe.andThen (ErdTable.getColumn ref.column)
    in
    relations
        |> List.filterMap (\r -> Maybe.map2 (\src ref -> ( r, src, ref )) (getColumn r.src) (getColumn r.ref))
        |> List.filter (\( _, src, ref ) -> src.kind /= ref.kind)


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "No relation with different types found"

                else
                    "Found " ++ (count |> String.pluralize "relation") ++ " with different types"
           )


view : ProjectRef -> SchemaName -> List Source -> (Cmd msg -> msg) -> List Model -> Html msg
view project defaultSchema sources send errors =
    div []
        [ if List.nonEmpty errors && project.organization.plan.dbAnalysis then
            div []
                [ Button.primary1 Tw.primary
                    [ onClick (errors |> scriptForRelationsWithDifferentTypes defaultSchema sources |> Ports.downloadFile "azimutt-fix-relations-with-different-types.sql" |> send) ]
                    [ text "Download SQL script to fix all" ]
                ]

          else
            div [] []
        , ProPlan.analysisResults project
            (errors |> List.sortBy (\( rel, _, _ ) -> ColumnRef.show defaultSchema rel.ref ++ " ← " ++ ColumnRef.show defaultSchema rel.src))
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
