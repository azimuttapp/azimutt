module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.IndexDuplicated exposing (Model, heading, rule, view)

import Components.Slices.ProPlan as ProPlan
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Libs.String as String
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


type alias Model =
    String



-- TODO


rule : Dict TableId ErdTable -> List Model
rule _ =
    []


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
