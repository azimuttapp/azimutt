module PagesComponents.Projects.Id_.Views.Erd.Table exposing (Model, viewTable)

import Components.Organisms.Table as Table
import Conf
import Dict
import Either exposing (Either(..))
import Html.Styled exposing (Attribute, Html, div)
import Html.Styled.Attributes exposing (css)
import Libs.Bool as B
import Libs.Hotkey as Hotkey
import Libs.Html.Styled.Events exposing (stopPointerDown)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel
import Libs.Tailwind.Utilities as Tu
import Models.ColumnOrder as ColumnOrder
import Models.ColumnRefFull exposing (ColumnRefFull)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Table as Table
import Models.Project.TableId as TableId exposing (TableId)
import Models.RelationFull as RelationFull exposing (RelationFull)
import Models.TableFull exposing (TableFull)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), DragState, FindPathMsg(..), Msg(..), VirtualRelation, VirtualRelationMsg(..))
import Tailwind.Utilities as Tw


type alias Model x =
    { x
        | hoverTable : Maybe TableId
        , hoverColumn : Maybe ColumnRef
        , cursorMode : CursorMode
        , virtualRelation : Maybe VirtualRelation
        , openedDropdown : HtmlId
        , dragging : Maybe DragState
    }


viewTable : Model x -> ZoomLevel -> TableFull -> List RelationFull -> Html Msg
viewTable model zoom table tableRelations =
    let
        tableId : HtmlId
        tableId =
            TableId.toHtmlId table.id

        _ =
            -- TODO: re-work model so only modified tables are updated
            Debug.log "viewTable" tableId

        columns : Ned ColumnName Table.Column
        columns =
            table.table.columns |> Ned.map (\_ col -> buildColumn tableRelations table col)

        drag : List (Attribute Msg)
        drag =
            B.cond (model.cursorMode == CursorDrag) [] [ stopPointerDown (.position >> DragStart tableId) ]
    in
    div
        ([ css
            [ Tw.select_none
            , Tw.absolute
            , Tw.transform
            , Tu.translate_x_y table.props.position.left table.props.position.top "px"
            , Tu.z (Conf.canvas.zIndex.tables + table.index)
            , Tu.when (table.props.size == Size.zero) [ Tw.invisible ]
            ]
         ]
            ++ drag
        )
        [ Table.table
            { id = tableId
            , ref = { schema = table.table.schema, table = table.table.name }
            , label = TableId.show table.id
            , isView = table.table.view
            , columns = table.props.columns |> List.filterMap (\name -> columns |> Ned.get name)
            , hiddenColumns = columns |> Ned.values |> Nel.filter (\c -> table.props.columns |> L.hasNot c.name) |> List.sortBy .index
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
                            , { label = "Bring forward", action = TableOrder table.id (table.index + 1), hotkey = Conf.hotkeys |> Dict.get "move-forward" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Send backward", action = TableOrder table.id (table.index - 1), hotkey = Conf.hotkeys |> Dict.get "move-backward" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            , { label = "Send to back", action = TableOrder table.id 0, hotkey = Conf.hotkeys |> Dict.get "move-to-back" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys }
                            ]
                  }
                , { label = "Find path for this table", action = Right { action = FindPathMsg (FPOpen (Just table.id) Nothing), hotkey = Nothing } }
                ]
            , state =
                { color = table.props.color
                , hover = model.hoverTable |> Maybe.map (\( schemaName, tableName ) -> { schema = schemaName, table = tableName })
                , hoverColumn = model.hoverColumn |> Maybe.map (\ref -> { schema = ref.table |> Tuple.first, table = ref.table |> Tuple.second, column = ref.column })
                , selected = table.props.selected
                , dragging = model.dragging |> M.any (\d -> d.id == tableId && d.init /= d.last)
                , openedDropdown = model.openedDropdown
                , showHiddenColumns = table.props.hiddenColumns
                }
            , actions =
                { hoverTable = ToggleHoverTable table.id
                , hoverColumn = \col -> ToggleHoverColumn { table = table.id, column = col }
                , clickHeader = SelectTable table.id
                , clickColumn = model.virtualRelation |> Maybe.map (\_ -> \col pos -> VirtualRelationMsg (VRUpdate { table = table.id, column = col } pos))
                , dblClickColumn = \col -> { table = table.id, column = col } |> B.cond (table.props.columns |> L.has col) HideColumn ShowColumn
                , clickRelations =
                    \cols ->
                        case cols of
                            [] ->
                                Noop "No table to show"

                            col :: [] ->
                                ShowTable ( col.column.schema, col.column.table )

                            _ ->
                                ShowTables (cols |> List.map (\col -> ( col.column.schema, col.column.table )))
                , clickHiddenColumns = ToggleHiddenColumns table.id
                , clickDropdown = DropdownToggle
                }
            , zoom = zoom
            }
        ]


buildColumn : List RelationFull -> TableFull -> Column -> Table.Column
buildColumn relations table column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map .text
    , isPrimaryKey = column.name |> Table.inPrimaryKey table.table |> M.isJust
    , inRelations = relations |> List.filter (RelationFull.hasRef table.id column.name) |> List.map .src |> List.map buildColumnRef
    , outRelations = relations |> List.filter (RelationFull.hasSrc table.id column.name) |> List.map .ref |> List.map buildColumnRef
    , uniques = table.table.uniques |> List.filter (\u -> u.columns |> Nel.has column.name) |> List.map (\u -> { name = u.name })
    , indexes = table.table.indexes |> List.filter (\i -> i.columns |> Nel.has column.name) |> List.map (\i -> { name = i.name })
    , checks = table.table.checks |> List.filter (\c -> c.columns |> L.has column.name) |> List.map (\c -> { name = c.name })
    }


buildColumnRef : ColumnRefFull -> Table.Relation
buildColumnRef ref =
    { column = { schema = ref.table.id |> Tuple.first, table = ref.table.id |> Tuple.second, column = ref.column.name }
    , nullable = ref.column.nullable
    , tableShown = ref.props |> M.isJust
    }
