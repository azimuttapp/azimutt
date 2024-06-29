module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.IndexOnForeignKeys exposing (Model, compute, heading, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Slices.PlanDialog as PlanDialog
import Dict exposing (Dict)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Libs.Html exposing (bText)
import Libs.Maybe as Maybe
import Libs.String as String
import Libs.Tailwind as Tw
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)


type alias Model =
    ( Relation, Bool )


compute : Dict TableId Table -> List Relation -> List Model
compute tables relations =
    -- same as libs/models/src/analyze/rules/indexOnRelation.ts
    relations
        |> List.concatMap
            (\r ->
                let
                    srcCol : List Model
                    srcCol =
                        if r.src |> hasIndex tables then
                            [ ( r, True ) ]

                        else
                            []

                    refCol : List Model
                    refCol =
                        if r.ref |> hasIndex tables then
                            [ ( r, False ) ]

                        else
                            []
                in
                srcCol ++ refCol
            )


hasIndex : Dict TableId Table -> ColumnRef -> Bool
hasIndex tables column =
    let
        srcTable : Maybe Table
        srcTable =
            tables |> Dict.get column.table

        ( srcPk, srcUniques, srcIndexes ) =
            ( srcTable |> Maybe.andThen (\t -> t.primaryKey |> Maybe.filter (\pk -> pk.columns.head == column.column))
            , srcTable |> Maybe.mapOrElse (\t -> t.uniques |> List.filter (\u -> u.columns.head == column.column)) []
            , srcTable |> Maybe.mapOrElse (\t -> t.indexes |> List.filter (\i -> i.columns.head == column.column)) []
            )
    in
    srcPk == Nothing && List.isEmpty srcUniques && List.isEmpty srcIndexes


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "All relations have indexes"

                else
                    "Found " ++ (count |> String.pluralize "relation") ++ " without index"
           )


view : (TableId -> Maybe PositionHint -> String -> msg) -> ProjectRef -> SchemaName -> List Model -> Html msg
view showTable project defaultSchema errors =
    div []
        [ div [ class "mb-1 text-gray-500" ]
            [ text "Adding index on relations may speed-up the joins, consider adding some."
            ]
        , PlanDialog.analysisResults project
            errors
            (\( r, isSrc ) ->
                div [ class "flex justify-between items-center my-1" ]
                    (if isSrc then
                        [ div []
                            [ span [] [ text (TableId.show defaultSchema r.src.table), text ".", bText (ColumnPath.show r.src.column) ]
                            , Icon.solid ArrowNarrowRight "inline mx-1"
                            , span [] [ text (TableId.show defaultSchema r.ref.table), text ".", text (ColumnPath.show r.ref.column) ]
                            , text " has no index."
                            ]
                        , Button.primary1 Tw.primary [ class "ml-3", onClick (showTable r.src.table Nothing "fk-no-index") ] [ text "Show table" ]
                        ]

                     else
                        [ div []
                            [ span [] [ text (TableId.show defaultSchema r.ref.table), text ".", bText (ColumnPath.show r.ref.column) ]
                            , Icon.solid ArrowNarrowLeft "inline mx-1"
                            , span [] [ text (TableId.show defaultSchema r.src.table), text ".", text (ColumnPath.show r.src.column) ]
                            , text " has no index."
                            ]
                        , Button.primary1 Tw.primary [ class "ml-3", onClick (showTable r.ref.table Nothing "fk-no-index") ] [ text "Show table" ]
                        ]
                    )
            )
        ]
