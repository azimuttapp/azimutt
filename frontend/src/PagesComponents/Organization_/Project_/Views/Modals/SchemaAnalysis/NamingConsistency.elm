module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.NamingConsistency exposing (Model, compute, heading, view)

import Components.Slices.PlanDialog as PlanDialog
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Libs.Html exposing (bText)
import Libs.List as List
import Libs.String as String
import Libs.StringCase exposing (StringCase(..), isCamelLower, isCamelUpper, isKebab, isSnakeLower, isSnakeUpper)
import Libs.Tuple3 as Tuple3
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)


type alias Model =
    Table


compute : Dict TableId Table -> List Model
compute tables =
    -- same as libs/models/src/analyze/rules/attributeNameInconsistent.ts & entityNameInconsistent.ts
    let
        ( ( camelUpper, camelLower ), ( snakeUpper, snakeLower ), kebab ) =
            tables
                |> Dict.values
                |> List.foldl
                    (\t ( ( cu, cl ), ( su, sl ), k ) ->
                        ( ( t.name |> isCamelUpper |> incOnTrue cu, t.name |> isCamelLower |> incOnTrue cl )
                        , ( t.name |> isSnakeUpper |> incOnTrue su, t.name |> isSnakeLower |> incOnTrue sl )
                        , t.name |> isKebab |> incOnTrue k
                        )
                    )
                    ( ( 0, 0 ), ( 0, 0 ), 0 )

        ( _, _, bestCaseTest ) =
            [ ( camelUpper, CamelUpper, isCamelUpper )
            , ( camelLower, CamelLower, isCamelLower )
            , ( snakeUpper, SnakeUpper, isSnakeUpper )
            , ( snakeLower, SnakeLower, isSnakeLower )
            , ( kebab, Kebab, isKebab )
            ]
                |> List.maximumBy Tuple3.first
                |> Maybe.withDefault ( 0, SnakeLower, isSnakeLower )

        bad : List Table
        bad =
            tables |> Dict.values |> List.filter (\t -> t.name |> bestCaseTest |> not)
    in
    bad


incOnTrue : Int -> Bool -> Int
incOnTrue value bool =
    if bool then
        value + 1

    else
        value


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "All tables have consistent naming case"

                else
                    "Found " ++ (count |> String.pluralize "table") ++ " with uncommon naming case"
           )


view : ProjectRef -> SchemaName -> List Model -> Html msg
view project defaultSchema errors =
    div [] [ PlanDialog.analysisResults project errors (\t -> div [] [ bText (TableId.show defaultSchema t.id), text " has uncommon naming case." ]) ]
