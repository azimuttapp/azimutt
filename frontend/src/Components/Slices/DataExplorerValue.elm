module Components.Slices.DataExplorerValue exposing (view)

import Components.Atoms.Icon as Icon
import DataSources.DbMiner.DbTypes exposing (RowQuery)
import Html exposing (Html, button, div)
import Html.Attributes exposing (class, title, type_)
import Html.Events exposing (onClick)
import Libs.Maybe as Maybe
import Libs.Nel exposing (Nel)
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId
import Models.QueryResult exposing (QueryResultColumnTarget)


view : (RowQuery -> msg) -> msg -> SchemaName -> Bool -> Bool -> Maybe DbValue -> QueryResultColumnTarget -> Html msg
view openRowDetails expandRow defaultSchema documentMode expanded value column =
    let
        -- TODO: contextual formatting: numbers, uuid, dates, may depend on context (results vs side bar)
        valueText : String
        valueText =
            value |> Maybe.mapOrElse DbValue.toString ""
    in
    if value |> Maybe.any (\v -> DbValue.isArray v || DbValue.isObject v) then
        if documentMode then
            div [] [ DbValue.viewRaw value ]

        else if expanded then
            div [ onClick expandRow, class "cursor-pointer" ] [ DbValue.viewRaw value ]

        else
            div [ onClick expandRow, title valueText, class "cursor-pointer" ] [ DbValue.view value ]

    else
        Maybe.map2
            (\o v ->
                div [ title valueText ]
                    [ DbValue.view value
                    , button
                        [ type_ "button"
                        , onClick (openRowDetails { source = o.ref.source, table = o.ref.table, primaryKey = Nel { column = o.ref.column, value = v } [] })
                        , title ("Display " ++ TableId.show defaultSchema o.ref.table ++ " row with " ++ ColumnPath.show o.ref.column ++ "=" ++ DbValue.toString v)
                        ]
                        [ Icon.solid Icon.ExternalLink "ml-1 w-4 h-4 inline" ]
                    ]
            )
            column.dataRef
            (value |> Maybe.filter (\v -> v /= DbNull))
            |> Maybe.withDefault (div [ title valueText ] [ DbValue.view value ])
