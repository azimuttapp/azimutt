module PagesComponents.Projects.Id_.Views.Erd.Table exposing (TableArgs, argsToString, stringToArgs, viewTable)

import Components.Organisms.Table as Table
import Conf
import Dict
import Either exposing (Either(..))
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (style)
import Libs.Bool as B
import Libs.Hotkey as Hotkey
import Libs.Html.Attributes exposing (css)
import Libs.Html.Events exposing (stopPointerDown)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Position
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.ColumnOrder as ColumnOrder
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), FindPathMsg(..), Msg(..), VirtualRelationMsg(..))
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))


type alias TableArgs =
    String


argsToString : String -> String -> Bool -> Bool -> TableArgs
argsToString openedDropdown openedPopover dragging virtualRelation =
    openedDropdown ++ "#" ++ openedPopover ++ "#" ++ B.cond dragging "Y" "N" ++ "#" ++ B.cond virtualRelation "Y" "N"


stringToArgs : TableArgs -> ( ( String, String ), ( Bool, Bool ) )
stringToArgs args =
    case args |> String.split "#" of
        [ openedDropdown, openedPopover, dragging, virtualRelation ] ->
            ( ( openedDropdown, openedPopover ), ( dragging == "Y", virtualRelation == "Y" ) )

        _ ->
            ( ( "", "" ), ( False, False ) )


viewTable : ZoomLevel -> CursorMode -> TableArgs -> Int -> ErdTableProps -> ErdTable -> Html Msg
viewTable zoom cursorMode args index props table =
    let
        ( ( openedDropdown, openedPopover ), ( dragging, virtualRelation ) ) =
            stringToArgs args

        ( columns, hiddenColumns ) =
            table.columns |> Ned.values |> Nel.map (buildColumn props) |> Nel.partition (\c -> props.shownColumns |> List.any (\col -> c.name == col))

        drag : List (Attribute Msg)
        drag =
            B.cond (cursorMode == CursorDrag) [] [ stopPointerDown (.position >> DragStart table.htmlId) ]

        zIndex : Int
        zIndex =
            Conf.canvas.zIndex.tables + index + B.cond (props.selected || dragging || (openedDropdown |> String.startsWith table.htmlId)) 1000 0
    in
    div
        ([ css [ "select-none absolute", B.cond (props.size == Size.zero) "invisible" "" ]
         , style "left" (String.fromFloat props.position.left ++ "px")
         , style "top" (String.fromFloat props.position.top ++ "px")
         , style "z-index" (String.fromInt zIndex)
         ]
            ++ drag
        )
        [ Table.table
            { id = table.htmlId
            , ref = { schema = table.schema, table = table.name }
            , label = table.label
            , isView = table.view
            , columns = columns |> List.sortBy (\c -> props.shownColumns |> List.indexOf c.name |> Maybe.withDefault 0)
            , hiddenColumns = hiddenColumns |> List.sortBy .index
            , settings =
                [ { label = "Hide table", action = Right { action = HideTable table.id, hotkey = Conf.hotkeys |> Dict.get "remove" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys } }
                , { label = "Sort columns", action = Left (ColumnOrder.all |> List.map (\o -> { label = ColumnOrder.show o, action = SortColumns table.id o, hotkey = Nothing })) }
                , { label = "Hide columns"
                  , action =
                        Left
                            [ { label = "Without relation", action = HideColumns table.id "relations", hotkey = Nothing }
                            , { label = "Regular ones", action = HideColumns table.id "regular", hotkey = Nothing }
                            , { label = "Nullable ones", action = HideColumns table.id "nullable", hotkey = Nothing }
                            , { label = "All", action = HideColumns table.id "all", hotkey = Nothing }
                            ]
                  }
                , { label = "Show columns"
                  , action =
                        Left
                            [ { label = "With relations", action = ShowColumns table.id "relations", hotkey = Nothing }
                            , { label = "All", action = ShowColumns table.id "all", hotkey = Nothing }
                            ]
                  }
                , { label = "Order"
                  , action =
                        Left
                            [ { label = "Bring to front", action = TableOrder table.id 1000, hotkey = Conf.hotkeys |> Dict.get "move-to-top" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Bring forward", action = TableOrder table.id (index + 1), hotkey = Conf.hotkeys |> Dict.get "move-forward" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Send backward", action = TableOrder table.id (index - 1), hotkey = Conf.hotkeys |> Dict.get "move-backward" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Send to back", action = TableOrder table.id 0, hotkey = Conf.hotkeys |> Dict.get "move-to-back" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            ]
                  }
                , { label = "Find path for this table", action = Right { action = FindPathMsg (FPOpen (Just table.id) Nothing), hotkey = Nothing } }
                ]
            , state =
                { color = props.color
                , isHover = props.isHover
                , highlightedColumns = props.highlightedColumns
                , selected = props.selected
                , dragging = dragging
                , openedDropdown = openedDropdown
                , openedPopover = openedPopover
                , showHiddenColumns = props.showHiddenColumns
                }
            , actions =
                { hoverTable = ToggleHoverTable table.id
                , hoverColumn = \col -> ToggleHoverColumn { table = table.id, column = col }
                , clickHeader = SelectTable table.id
                , clickColumn = B.maybe virtualRelation (\col pos -> VirtualRelationMsg (VRUpdate { table = table.id, column = col } pos))
                , dblClickColumn = \col -> { table = table.id, column = col } |> B.cond (props.shownColumns |> List.has col) HideColumn ShowColumn
                , clickRelations =
                    \cols isOut ->
                        Just (B.cond isOut (PlaceRight props.position props.size) (PlaceLeft props.position))
                            |> (\hint ->
                                    case cols of
                                        [] ->
                                            Noop "No table to show"

                                        col :: [] ->
                                            ShowTable ( col.column.schema, col.column.table ) hint

                                        _ ->
                                            ShowTables (cols |> List.map (\col -> ( col.column.schema, col.column.table ))) hint
                               )
                , hoverHiddenColumns = PopoverSet
                , clickHiddenColumns = ToggleHiddenColumns table.id
                , clickDropdown = DropdownToggle
                }
            , zoom = zoom
            }
        ]


buildColumn : ErdTableProps -> ErdColumn -> Table.Column
buildColumn props column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map .text
    , isPrimaryKey = column.isPrimaryKey
    , inRelations = column.inRelations |> List.map (buildColumnRelation props)
    , outRelations = column.outRelations |> List.map (buildColumnRelation props)
    , uniques = column.uniques |> List.map (\u -> { name = u })
    , indexes = column.indexes |> List.map (\i -> { name = i })
    , checks = column.checks |> List.map (\c -> { name = c })
    }


buildColumnRelation : ErdTableProps -> ErdColumnRef -> Table.Relation
buildColumnRelation props relation =
    { column = { schema = relation.table |> Tuple.first, table = relation.table |> Tuple.second, column = relation.column }
    , nullable = relation.nullable
    , tableShown = props.relatedTables |> Dict.get relation.table |> Maybe.mapOrElse .shown False
    }
