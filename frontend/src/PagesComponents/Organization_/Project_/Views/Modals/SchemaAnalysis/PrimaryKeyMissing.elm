module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.PrimaryKeyMissing exposing (Model, compute, heading, view)

import Components.Atoms.Button as Button
import Components.Slices.PlanDialog as PlanDialog
import Dict exposing (Dict)
import Html exposing (Html, div, p, text)
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
    -- same as libs/models/src/analyze/rules/primaryKeyMissing.ts
    tables |> Dict.values |> List.filter (\t -> t.primaryKey == Nothing && t.view == False)


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "All tables have a primary key"

                else
                    "Found " ++ (count |> String.pluralize "table") ++ " without a primary key"
           )


view : (TableId -> Maybe PositionHint -> String -> msg) -> ProjectRef -> SchemaName -> List Model -> Html msg
view showTable project defaultSchema errors =
    div []
        [ p [ class "mb-3 text-sm text-gray-500" ] [ text "It's not always required to have a primary key but strongly encouraged in most case. Make sure this is what you want!" ]
        , PlanDialog.analysisResults project
            errors
            (\t ->
                div [ class "flex justify-between items-center my-1" ]
                    [ div [] [ bText (TableId.show defaultSchema t.id), text " has no primary key" ]
                    , Button.primary1 Tw.primary [ class "ml-3", onClick (showTable t.id Nothing "no-primary-key") ] [ text "Show table" ]
                    ]
            )
        ]
