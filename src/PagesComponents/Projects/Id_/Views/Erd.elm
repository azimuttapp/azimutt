module PagesComponents.Projects.Id_.Views.Erd exposing (Model, viewErd)

import Components.Organisms.Table as Table
import Conf
import Dict exposing (Dict)
import Either exposing (Either(..))
import Html.Styled exposing (Attribute, Html, div, main_)
import Html.Styled.Attributes exposing (class, classList, css, id)
import Html.Styled.Keyed as Keyed
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.Dict as D
import Libs.DomInfo exposing (DomInfo)
import Libs.Html.Styled.Attributes exposing (onPointerDownStopPropagation)
import Libs.Html.Styled.Events exposing (onWheel)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.Theme exposing (Theme)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel
import Libs.Tailwind.Utilities as Tu
import Models.ColumnOrder as ColumnOrder
import Models.ColumnRefFull exposing (ColumnRefFull)
import Models.Project exposing (Project)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import Models.RelationFull as RelationFull exposing (RelationFull)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), DragState, Msg(..), VirtualRelation)
import PagesComponents.Projects.Id_.Updates.Drag as Drag
import Tailwind.Utilities as Tw


type alias Model x =
    { x
        | cursorMode : CursorMode
        , selectionBox : Maybe Area
        , virtualRelation : Maybe VirtualRelation
        , domInfos : Dict HtmlId DomInfo
        , openedDropdown : HtmlId
        , dragging : Maybe DragState
        , hoverTable : Maybe TableId
        , hoverColumn : Maybe ColumnRef
    }


viewErd : Theme -> Model x -> Project -> Html Msg
viewErd _ model project =
    let
        layoutTablesDict : Dict TableId ( TableProps, Int )
        layoutTablesDict =
            project.layout.tables |> L.zipWithIndex |> D.fromListMap (\( t, _ ) -> t.id)

        layoutTablesDictSize : Int
        layoutTablesDictSize =
            layoutTablesDict |> Dict.size

        shownRelations : List RelationFull
        shownRelations =
            project.relations
                |> List.filter (\r -> Dict.member r.src.table layoutTablesDict || Dict.member r.ref.table layoutTablesDict)
                |> List.filterMap (buildRelationFull project.tables layoutTablesDict layoutTablesDictSize model.domInfos)

        position : Position
        position =
            project.layout.canvas.position |> (\pos -> model.dragging |> M.filter (\d -> d.id == Conf.ids.erd) |> M.mapOrElse (\d -> pos |> Drag.move d 1) pos)
    in
    main_
        [ class "tw-erd"
        , classList
            [ ( "tw-cursor-hand", model.cursorMode == CursorDrag && model.dragging == Nothing && model.virtualRelation == Nothing )
            , ( "tw-cursor-hand-drag", model.cursorMode == CursorDrag && model.dragging /= Nothing && model.virtualRelation == Nothing )
            , ( "tw-cursor-cross", model.virtualRelation /= Nothing )
            ]
        , id Conf.ids.erd
        , onWheel OnWheel
        , onPointerDownStopPropagation (DragStart (B.cond (model.cursorMode == CursorDrag) Conf.ids.erd Conf.ids.selectionBox))
        ]
        [ div [ class "tw-canvas", css [ Tw.transform, Tw.origin_top_left, Tu.translate_x_y position.left position.top "px", Tu.scale project.layout.canvas.zoom ] ]
            [ viewTables model project project.tables project.layout.tables shownRelations
            , model.selectionBox |> M.mapOrElse viewSelectionBox (div [] [])
            ]
        ]


viewTables : Model x -> Project -> Dict TableId Table -> List TableProps -> List RelationFull -> Html Msg
viewTables model project tables layout relations =
    Keyed.node "div"
        [ class "tables" ]
        (layout
            |> List.reverse
            |> L.filterZip (\p -> tables |> Dict.get p.id)
            |> L.zipWith (\( _, table ) -> ( model.domInfos |> Dict.get (TableId.toHtmlId table.id), relations |> List.filter (RelationFull.hasTableLink table.id) ))
            |> List.indexedMap (\i ( ( props, table ), ( domInfos, tableRelations ) ) -> ( TableId.toString table.id, viewTable model project i table props domInfos tableRelations ))
        )


viewTable : Model x -> Project -> Int -> Table -> TableProps -> Maybe DomInfo -> List RelationFull -> Html Msg
viewTable model project index table props domInfo tableRelations =
    let
        tableId : HtmlId
        tableId =
            TableId.toHtmlId table.id

        position : Position
        position =
            model.dragging |> M.filter (\d -> d.id == tableId) |> M.mapOrElse (\d -> props.position |> Drag.move d project.layout.canvas.zoom) props.position

        columns : Ned ColumnName Table.Column
        columns =
            table.columns |> Ned.map (\_ col -> buildColumn tableRelations table col)

        drag : List (Attribute Msg)
        drag =
            B.cond (model.cursorMode == CursorDrag) [] [ onPointerDownStopPropagation (DragStart tableId) ]
    in
    div (drag ++ [ css ([ Tw.select_none, Tw.absolute, Tw.transform, Tu.translate_x_y position.left position.top "px" ] ++ (domInfo |> M.mapOrElse (\_ -> []) [ Tw.invisible ])) ])
        [ Table.table
            { id = tableId
            , ref = { schema = table.schema, table = table.name }
            , label = TableId.show table.id
            , isView = table.view
            , columns = props.columns |> List.filterMap (\name -> columns |> Ned.get name)
            , hiddenColumns = columns |> Ned.values |> Nel.filter (\c -> props.columns |> L.hasNot c.name)
            , settings =
                [ { label = "Hide table", action = Right (HideTable table.id) }
                , { label = "Sort columns", action = Left (ColumnOrder.all |> List.map (\o -> { label = ColumnOrder.show o, action = SortColumns table.id o })) }
                , { label = "Hide columns"
                  , action =
                        Left
                            [ { label = "Regular ones", action = HideColumns table.id "regular" }
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
                            , { label = "Bring forward", action = TableOrder table.id (index + 1) }
                            , { label = "Send backward", action = TableOrder table.id (index - 1) }
                            , { label = "Send to back", action = TableOrder table.id 0 }
                            ]
                  }
                , { label = "Find path for this table", action = Right FindPathMsg }
                ]
            , state =
                { color = props.color
                , hover = model.hoverTable |> Maybe.map (\( schemaName, tableName ) -> { schema = schemaName, table = tableName })
                , hoverColumn = model.hoverColumn |> Maybe.map (\ref -> { schema = ref.table |> Tuple.first, table = ref.table |> Tuple.second, column = ref.column })
                , selected = props.selected
                , dragging = model.dragging |> M.filter (\d -> d.id == tableId && d.init /= d.last) |> M.isJust
                , openedDropdown = model.openedDropdown
                , showHiddenColumns = props.hiddenColumns
                }
            , actions =
                { toggleHover = ToggleHoverTable table.id
                , toggleHoverColumn = \c -> ToggleHoverColumn { table = table.id, column = c }
                , toggleSelected = SelectTable table.id
                , toggleDropdown = DropdownToggle
                , toggleHiddenColumns = ToggleHiddenColumns table.id
                , toggleColumn = \col -> { table = table.id, column = col } |> B.cond (props.columns |> L.has col) HideColumn ShowColumn
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
            }
        ]


viewSelectionBox : Area -> Html Msg
viewSelectionBox area =
    div
        [ class "tw-selection-area"
        , css
            [ Tw.transform
            , Tu.translate_x_y area.position.left area.position.top "px"
            , Tu.w area.size.width "px"
            , Tu.h area.size.height "px"
            , Color.border Color.teal 400
            , Tw.border_2
            , Color.bg Color.teal 400
            , Tw.bg_opacity_25
            ]
        ]
        []



-- HELPERS


buildColumn : List RelationFull -> Table -> Column -> Table.Column
buildColumn relations table column =
    { name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map .text
    , isPrimaryKey = column.name |> Table.inPrimaryKey table |> M.isJust
    , inRelations = relations |> List.filter (RelationFull.hasRef table.id column.name) |> List.map .src |> List.map buildColumnRef
    , outRelations = relations |> List.filter (RelationFull.hasSrc table.id column.name) |> List.map .ref |> List.map buildColumnRef
    , uniques = table.uniques |> List.filter (\u -> u.columns |> Nel.has column.name) |> List.map (\u -> { name = u.name })
    , indexes = table.indexes |> List.filter (\i -> i.columns |> Nel.has column.name) |> List.map (\i -> { name = i.name })
    , checks = table.checks |> List.filter (\c -> c.columns |> L.has column.name) |> List.map (\c -> { name = c.name })
    }


buildColumnRef : ColumnRefFull -> Table.Relation
buildColumnRef ref =
    { column = { schema = ref.table.id |> Tuple.first, table = ref.table.id |> Tuple.second, column = ref.column.name }
    , nullable = ref.column.nullable
    , tableShown = ref.props |> M.isJust
    }


buildRelationFull : Dict TableId Table -> Dict TableId ( TableProps, Int ) -> Int -> Dict HtmlId DomInfo -> Relation -> Maybe RelationFull
buildRelationFull tables layoutTables layoutTablesSize domInfos rel =
    Maybe.map2 (\src ref -> { name = rel.name, src = src, ref = ref, origins = rel.origins })
        (buildColumnRefFull tables layoutTables layoutTablesSize domInfos rel.src)
        (buildColumnRefFull tables layoutTables layoutTablesSize domInfos rel.ref)


buildColumnRefFull : Dict TableId Table -> Dict TableId ( TableProps, Int ) -> Int -> Dict HtmlId DomInfo -> ColumnRef -> Maybe ColumnRefFull
buildColumnRefFull tables layoutTables layoutTablesSize domInfos ref =
    (tables |> Dict.get ref.table |> M.andThenZip (\table -> table.columns |> Ned.get ref.column))
        |> Maybe.map
            (\( table, column ) ->
                { ref = ref
                , table = table
                , column = column
                , props =
                    M.zip
                        (layoutTables |> Dict.get ref.table)
                        (domInfos |> Dict.get (TableId.toHtmlId ref.table))
                        |> Maybe.map (\( ( t, i ), d ) -> ( t, layoutTablesSize - 1 - i, d.size ))
                }
            )
