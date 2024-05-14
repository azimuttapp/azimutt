module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.TableWithoutIndex exposing (Model, compute, heading, view)

import Components.Atoms.Button as Button
import Components.Slices.ProPlan as ProPlan
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Libs.Html exposing (bText)
import Libs.String as String
import Libs.Tailwind as Tw
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)


type alias Model =
    Table


compute : Dict TableId Table -> List Model
compute tables =
    -- same as libs/models/src/analyze/rules/entityNoIndex.ts
    tables
        |> Dict.values
        |> List.filter (\t -> t.primaryKey == Nothing && List.isEmpty t.uniques && List.isEmpty t.indexes)
        |> List.sortBy (\t -> t.columns |> Dict.size |> negate)


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "No table without index found"

                else
                    "Found " ++ (count |> String.pluralize "table") ++ " without index"
           )


view : (TableId -> Maybe PositionHint -> String -> msg) -> ProjectRef -> SchemaName -> List Model -> Html msg
view showTable project defaultSchema errors =
    div []
        [ div [ class "mb-1 text-gray-500" ]
            [ text "Indexes allow fast querying, depending on your table usage, it can be great to create a few indexes."
            ]
        , ProPlan.analysisResults project
            errors
            (\t ->
                div [ class "flex justify-between items-center my-1" ]
                    [ div [] [ bText (TableId.show defaultSchema t.id), text " has no index" ]
                    , Button.primary1 Tw.primary [ class "ml-3", onClick (showTable t.id Nothing "no-primary-key") ] [ text "Show table" ]
                    ]
            )
        ]
