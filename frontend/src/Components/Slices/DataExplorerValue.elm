module Components.Slices.DataExplorerValue exposing (view)

import Components.Atoms.Icon as Icon
import Html exposing (Html, button, div)
import Html.Attributes exposing (class, title, type_)
import Html.Events exposing (onClick)
import Libs.Maybe as Maybe
import Libs.Nel exposing (Nel)
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId
import Models.QueryResult exposing (QueryResultColumnTarget)
import Services.QueryBuilder as QueryBuilder


view : (QueryBuilder.RowQuery -> msg) -> msg -> SchemaName -> Bool -> Maybe JsValue -> QueryResultColumnTarget -> Html msg
view openRow expandRow defaultSchema expanded value column =
    let
        -- TODO: contextual formatting: numbers, uuid, dates, may depend on context (results vs side bar)
        valueText : String
        valueText =
            value |> Maybe.mapOrElse JsValue.toString ""
    in
    if value |> Maybe.any (\v -> JsValue.isArray v || JsValue.isObject v) then
        div [ onClick expandRow, title valueText, class "cursor-pointer" ]
            [ if expanded then
                JsValue.viewRaw value

              else
                JsValue.view value
            ]

    else
        Maybe.map2
            (\o v ->
                div [ title valueText ]
                    [ JsValue.view value
                    , button
                        [ type_ "button"
                        , onClick (openRow { table = o.ref.table, primaryKey = Nel { column = o.ref.column, value = v } [] })
                        , title ("Open " ++ TableId.show defaultSchema o.ref.table ++ " with " ++ ColumnPath.show o.ref.column ++ "=" ++ JsValue.toString v)
                        ]
                        [ Icon.solid Icon.ExternalLink "ml-1 w-4 h-4 inline" ]
                    ]
            )
            column.open
            (value |> Maybe.filter (\v -> v /= JsValue.Null))
            |> Maybe.withDefault (div [ title valueText ] [ JsValue.view value ])
