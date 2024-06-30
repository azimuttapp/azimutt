module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.IndexDuplicated exposing (Model, compute, heading, view)

import Components.Slices.PlanDialog as PlanDialog
import Dict exposing (Dict)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, title)
import Libs.Html exposing (bText)
import Libs.List as List
import Libs.Nel as Nel exposing (Nel)
import Libs.String as String
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.Index exposing (Index)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)


type alias Model =
    ( Table, Index, List Index )


compute : Dict TableId Table -> List Model
compute tables =
    -- same as libs/models/src/analyze/rules/indexDuplicated.ts
    tables
        |> Dict.values
        |> List.concatMap
            (\t ->
                t.indexes
                    -- start with indexes if few columns
                    |> List.sortBy (\i -> ( i.columns |> Nel.length, i.name ))
                    -- get duplicates
                    |> getDuplicate []
                    -- keep only duplicated indexes
                    |> List.filter (\( _, dups ) -> List.nonEmpty dups)
                    |> List.map (\( i, dups ) -> ( t, i, dups ))
            )


getDuplicate : List ( Index, List Index ) -> List Index -> List ( Index, List Index )
getDuplicate duplicates indexes =
    case indexes of
        head :: tail ->
            getDuplicate (( head, tail |> List.filter (\t -> head.columns |> Nel.indexedAll (\i hc -> Nel.get i t.columns == Just hc)) ) :: duplicates) tail

        _ ->
            duplicates


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "No duplicated index found"

                else
                    "Found " ++ (count |> String.pluralize "duplicated index")
           )


view : ProjectRef -> SchemaName -> List Model -> Html msg
view project defaultSchema errors =
    div []
        [ PlanDialog.analysisResults project
            errors
            (\( t, i, dups ) ->
                div []
                    ([ text "In table "
                     , bText (TableId.show defaultSchema t.id)
                     , text ", index "
                     , span [ class "underline", title (i.columns |> titleColumns) ] [ text i.name ]
                     , text " is included in "
                     ]
                        ++ (dups
                                |> List.map (\d -> span [ class "underline", title (d.columns |> titleColumns) ] [ text d.name ])
                                |> List.intersperse (text ", ")
                           )
                    )
            )
        ]


titleColumns : Nel ColumnPath -> String
titleColumns columns =
    if List.isEmpty columns.tail then
        "Column: " ++ (columns.head |> ColumnPath.toString)

    else
        "Columns: " ++ (columns |> Nel.toList |> List.map ColumnPath.toString |> String.join ", ")
