module PagesComponents.Projects.Id_.Views.Erd.Table exposing (Model, viewTable)

import Components.Organisms.Table as Table
import Conf
import Either exposing (Either(..))
import Html.Styled exposing (Attribute, Html, div)
import Html.Styled.Attributes exposing (css)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (onPointerDownStopPropagation)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
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
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), DragState, Msg(..))
import PagesComponents.Projects.Id_.Updates.Drag as Drag
import Tailwind.Utilities as Tw


type alias Model x =
    { x
        | cursorMode : CursorMode
        , openedDropdown : HtmlId
        , dragging : Maybe DragState
        , hoverTable : Maybe TableId
        , hoverColumn : Maybe ColumnRef
    }


viewTable : Model x -> ZoomLevel -> TableFull -> List RelationFull -> Html Msg
viewTable model zoom table tableRelations =
    let
        tableId : HtmlId
        tableId =
            TableId.toHtmlId table.id

        position : Position
        position =
            model.dragging |> M.filter (\d -> d.id == tableId) |> M.mapOrElse (\d -> table.props.position |> Drag.move d zoom) table.props.position

        columns : Ned ColumnName Table.Column
        columns =
            table.table.columns |> Ned.map (\_ col -> buildColumn tableRelations table col)

        drag : List (Attribute Msg)
        drag =
            B.cond (model.cursorMode == CursorDrag) [] [ onPointerDownStopPropagation (DragStart tableId) ]
    in
    div (drag ++ [ css ([ Tw.select_none, Tw.absolute, Tw.transform, Tu.translate_x_y position.left position.top "px", Tu.z (Conf.canvas.zIndex.tables + table.index) ] ++ B.cond (table.props.size == Size.zero) [ Tw.invisible ] []) ])
        [ Table.table
            { id = tableId
            , ref = { schema = table.table.schema, table = table.table.name }
            , label = TableId.show table.id
            , isView = table.table.view
            , columns = table.props.columns |> List.filterMap (\name -> columns |> Ned.get name)
            , hiddenColumns = columns |> Ned.values |> Nel.filter (\c -> table.props.columns |> L.hasNot c.name) |> List.sortBy .index
            , settings =
                [ { label = "Hide table", action = Right (HideTable table.id) }
                , { label = "Sort columns", action = Left (ColumnOrder.all |> List.map (\o -> { label = ColumnOrder.show o, action = SortColumns table.id o })) }
                , { label = "Hide columns"
                  , action =
                        Left
                            [ { label = "Without relation", action = HideColumns table.id "relations" }
                            , { label = "Regular ones", action = HideColumns table.id "regular" }
                            , { label = "Nullable ones", action = HideColumns table.id "nullable" }
                            , { label = "All", action = HideColumns table.id "all" }
                            ]
                  }
                , { label = "Show columns"
                  , action =
                        Left
                            [ { label = "With relations", action = ShowColumns table.id "relations" }
                            , { label = "All", action = ShowColumns table.id "all" }
                            ]
                  }
                , { label = "Order"
                  , action =
                        Left
                            [ { label = "Bring to front", action = TableOrder table.id 1000 }
                            , { label = "Bring forward", action = TableOrder table.id (table.index + 1) }
                            , { label = "Send backward", action = TableOrder table.id (table.index - 1) }
                            , { label = "Send to back", action = TableOrder table.id 0 }
                            ]
                  }
                , { label = "Find path for this table", action = Right FindPathMsg }
                ]
            , state =
                { color = table.props.color
                , hover = model.hoverTable |> Maybe.map (\( schemaName, tableName ) -> { schema = schemaName, table = tableName })
                , hoverColumn = model.hoverColumn |> Maybe.map (\ref -> { schema = ref.table |> Tuple.first, table = ref.table |> Tuple.second, column = ref.column })
                , selected = table.props.selected
                , dragging = model.dragging |> M.filter (\d -> d.id == tableId && d.init /= d.last) |> M.isJust
                , openedDropdown = model.openedDropdown
                , showHiddenColumns = table.props.hiddenColumns
                }
            , actions =
                { toggleHover = ToggleHoverTable table.id
                , toggleHoverColumn = \c -> ToggleHoverColumn { table = table.id, column = c }
                , toggleSelected = SelectTable table.id
                , toggleDropdown = DropdownToggle
                , toggleHiddenColumns = ToggleHiddenColumns table.id
                , toggleColumn = \col -> { table = table.id, column = col } |> B.cond (table.props.columns |> L.has col) HideColumn ShowColumn
                , showRelations =
                    \cols ->
                        case cols of
                            [] ->
                                Noop "No table to show"

                            col :: [] ->
                                ShowTable ( col.column.schema, col.column.table )

                            _ ->
                                ShowTables (cols |> List.map (\col -> ( col.column.schema, col.column.table )))
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
