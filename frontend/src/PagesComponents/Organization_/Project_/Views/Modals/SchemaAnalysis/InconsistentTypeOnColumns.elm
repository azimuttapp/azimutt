module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.InconsistentTypeOnColumns exposing (Model, compute, heading, view)

import Components.Molecules.Tooltip as Tooltip
import Components.Slices.PlanDialog as PlanDialog
import Conf
import Dict exposing (Dict)
import Html exposing (Html, div, p, span, text)
import Html.Attributes exposing (class)
import Libs.Html exposing (bText)
import Libs.List as List
import Libs.String as String
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


type alias Model =
    ( ColumnName, List ( ColumnType, List TableId ) )


compute : Dict TableId ErdTable -> List Model
compute tables =
    -- same as libs/models/src/analyze/rules/attributeInconsistentType.ts
    tables
        |> Dict.values
        |> List.concatMap (\t -> t.columns |> Dict.values |> List.filter (\c -> c.kind /= Conf.schema.column.unknownType) |> List.map (\c -> { table = t.id, column = c.path |> ColumnPath.toString, kind = c.kind }))
        |> List.groupBy .column
        |> Dict.toList
        |> List.map (\( col, cols ) -> ( col, cols |> List.groupBy .kind |> Dict.map (\_ -> List.map .table) |> Dict.toList ))
        |> List.filter (\( _, cols ) -> (cols |> List.length) > 1)


heading : List Model -> String
heading errors =
    List.length errors
        |> (\count ->
                if count == 0 then
                    "No heterogeneous types found"

                else
                    "Found " ++ (count |> String.pluralize "column") ++ " with heterogeneous types"
           )


view : ProjectRef -> SchemaName -> List Model -> Html msg
view project defaultSchema errors =
    div []
        [ p [ class "mb-1 text-sm text-gray-500" ]
            [ text
                ("There is nothing wrong intrinsically with heterogeneous types "
                    ++ "but sometimes, the same concept stored in different format may not be ideal and having everything aligned is clearer. "
                    ++ "But of course, not every column with the same name is the same thing, so just look at the to know, not to fix everything."
                )
            ]
        , PlanDialog.analysisResults project
            errors
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
