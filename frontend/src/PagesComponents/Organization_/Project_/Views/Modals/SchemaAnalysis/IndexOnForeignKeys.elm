module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.IndexOnForeignKeys exposing (Model, heading, rule, view)

import Components.Slices.ProPlan as ProPlan
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Libs.Maybe as Maybe
import Libs.String as String
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models.ErdIndex exposing (ErdIndex)
import PagesComponents.Organization_.Project_.Models.ErdPrimaryKey exposing (ErdPrimaryKey)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdUnique exposing (ErdUnique)


type alias Model =
    Relation


rule : Dict TableId ErdTable -> List Relation -> List Model
rule _ relations =
    relations
        |> List.filterMap
            (\r ->
                {- let
                       srcTable : Maybe ErdTable
                       srcTable =
                           tables |> Dict.get r.src.table

                       ( srcPk, srcUniques, srcIndexes ) =
                           ( srcTable |> Maybe.andThen (\t -> t.primaryKey |> Maybe.filter (\pk -> pk.columns.head == r.src.column))
                           , srcTable |> Maybe.mapOrElse (\t -> t.uniques |> List.filter (\u -> u.columns.head == r.src.column)) []
                           , srcTable |> Maybe.mapOrElse (\t -> t.indexes |> List.filter (\i -> i.columns.head == r.src.column)) []
                           )
                   in
                -}
                Just r
            )


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "No error found"

                else
                    "Found " ++ (count |> String.pluralize "error")
           )


view : ProjectRef -> SchemaName -> List Model -> Html msg
view project _ errors =
    div []
        [ ProPlan.analysisResults project errors (\t -> div [] [ text t ])
        ]
