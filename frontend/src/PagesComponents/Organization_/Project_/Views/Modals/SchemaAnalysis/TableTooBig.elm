module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.TableTooBig exposing (Model, compute, heading, view)

import Components.Slices.ProPlan as ProPlan
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import Services.Backend as Backend


type alias Model =
    Table


compute : Dict TableId Table -> List Model
compute tables =
    tables
        |> Dict.values
        |> List.filter (\t -> (t.columns |> Dict.size) > 30)
        |> List.sortBy (\t -> t.columns |> Dict.size |> negate)


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "No big table found"

                else
                    "Found " ++ (count |> String.pluralize "table") ++ " too big"
           )


view : ProjectRef -> SchemaName -> List Model -> Html msg
view project defaultSchema errors =
    div []
        [ div [ class "mb-1 text-gray-500" ]
            [ text "See "
            , extLink (Backend.blogArticleUrl "why-you-should-avoid-tables-with-many-columns-and-how-to-fix-them")
                [ css [ "link" ] ]
                [ text "Why you should avoid tables with many columns, and how to fix them"
                ]
            ]
        , ProPlan.analysisResults project errors (\t -> div [] [ text ((t.columns |> Dict.size |> String.pluralize "column") ++ ": "), bText (TableId.show defaultSchema t.id) ])
        ]
