module PagesComponents.Projects.Id_.Views.Erd.Table exposing (TableArgs, argsToString, stringToArgs, viewTable)

import Components.Organisms.Table as Table
import Conf
import DataSources.SqlParser.Parsers.ColumnType as ColumnType
import Dict
import Either exposing (Either(..))
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (style)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as B
import Libs.Hotkey as Hotkey
import Libs.Html.Attributes exposing (css)
import Libs.Html.Events exposing (PointerEvent, stopPointerDown)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.ColumnOrder as ColumnOrder
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), FindPathMsg(..), Msg(..), VirtualRelationMsg(..))
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Projects.Id_.Views.Modals.ColumnContextMenu exposing (viewColumnContextMenu, viewHiddenColumnContextMenu)


type alias TableArgs =
    String


argsToString : String -> String -> Bool -> Bool -> Bool -> TableArgs
argsToString openedDropdown openedPopover dragging virtualRelation useBasicTypes =
    openedDropdown ++ "#" ++ openedPopover ++ "#" ++ B.cond dragging "Y" "N" ++ "#" ++ B.cond virtualRelation "Y" "N" ++ "#" ++ B.cond useBasicTypes "Y" "N"


stringToArgs : TableArgs -> ( ( String, String ), ( Bool, Bool, Bool ) )
stringToArgs args =
    case args |> String.split "#" of
        [ openedDropdown, openedPopover, dragging, virtualRelation, useBasicTypes ] ->
            ( ( openedDropdown, openedPopover ), ( dragging == "Y", virtualRelation == "Y", useBasicTypes == "Y" ) )

        _ ->
            ( ( "", "" ), ( False, False, False ) )


viewTable : ErdConf -> ZoomLevel -> CursorMode -> TableArgs -> Int -> ErdTableProps -> ErdTable -> Html Msg
viewTable conf zoom cursorMode args index props table =
    let
        ( ( openedDropdown, openedPopover ), ( dragging, virtualRelation, useBasicTypes ) ) =
            stringToArgs args

        ( columns, hiddenColumns ) =
            table.columns |> Ned.values |> Nel.map (buildColumn useBasicTypes props) |> Nel.partition (\c -> props.shownColumns |> List.any (\col -> c.name == col))

        drag : List (Attribute Msg)
        drag =
            B.cond (cursorMode == CursorDrag || not conf.move) [] [ stopPointerDown (handleTablePointerDown table.htmlId) ]

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
                [ Maybe.when conf.layout { label = "Hide table", action = Right { action = HideTable table.id, hotkey = Conf.hotkeys |> Dict.get "remove" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys } }
                , Maybe.when conf.layout { label = "Sort columns", action = Left (ColumnOrder.all |> List.map (\o -> { label = ColumnOrder.show o, action = SortColumns table.id o, hotkey = Nothing })) }
                , Maybe.when conf.layout
                    { label = "Hide columns"
                    , action =
                        Left
                            [ { label = "Without relation", action = HideColumns table.id "relations", hotkey = Nothing }
                            , { label = "Regular ones", action = HideColumns table.id "regular", hotkey = Nothing }
                            , { label = "Nullable ones", action = HideColumns table.id "nullable", hotkey = Nothing }
                            , { label = "All", action = HideColumns table.id "all", hotkey = Nothing }
                            ]
                    }
                , Maybe.when conf.layout
                    { label = "Show columns"
                    , action =
                        Left
                            [ { label = "With relations", action = ShowColumns table.id "relations", hotkey = Nothing }
                            , { label = "All", action = ShowColumns table.id "all", hotkey = Nothing }
                            ]
                    }
                , Maybe.when conf.layout
                    { label = "Order"
                    , action =
                        Left
                            [ { label = "Bring forward", action = TableOrder table.id (index + 1), hotkey = Conf.hotkeys |> Dict.get "move-forward" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Send backward", action = TableOrder table.id (index - 1), hotkey = Conf.hotkeys |> Dict.get "move-backward" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Bring to front", action = TableOrder table.id 1000, hotkey = Conf.hotkeys |> Dict.get "move-to-top" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Send to back", action = TableOrder table.id 0, hotkey = Conf.hotkeys |> Dict.get "move-to-back" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            ]
                    }
                , Maybe.when conf.findPath { label = "Find path for this table", action = Right { action = FindPathMsg (FPOpen (Just table.id) Nothing), hotkey = Nothing } }
                ]
                    |> List.filterMap identity
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
                , contextMenuColumn = \i col -> ContextMenuCreate (B.cond (props.shownColumns |> List.has col) viewColumnContextMenu viewHiddenColumnContextMenu i { table = table.id, column = col })
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
            , conf = { layout = conf.layout, move = conf.move, select = conf.select, hover = conf.hover }
            }
        ]


handleTablePointerDown : HtmlId -> PointerEvent -> Msg
handleTablePointerDown htmlId e =
    if e.button == MainButton then
        e |> .position |> DragStart htmlId

    else if e.button == MiddleButton then
        e |> .position |> DragStart Conf.ids.erd

    else
        Noop "No match on table pointer down"


buildColumn : Bool -> ErdTableProps -> ErdColumn -> Table.Column
buildColumn useBasicTypes props column =
    { index = column.index
    , name = column.name
    , kind =
        if useBasicTypes then
            column.kind |> ColumnType.parse |> ColumnType.toString

        else
            column.kind
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
