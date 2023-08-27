module PagesComponents.Organization_.Project_.Views.Erd.Table exposing (TableArgs, argsToString, stringToArgs, viewTable)

import Components.Organisms.Table as Table
import Conf
import Dict
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (classList)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.Html.Events exposing (PointerEvent, onPointerDown)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.Tag as Tag
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Models.Position as Position
import Models.Project.ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType
import Models.Project.CustomTypeValue as CustomTypeValue
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId
import Models.Project.TableMeta exposing (TableMeta)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn, ErdNestedColumns(..))
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Organization_.Project_.Views.Modals.ColumnContextMenu as ColumnContextMenu
import PagesComponents.Organization_.Project_.Views.Modals.TableContextMenu as TableContextMenu
import Set


type alias TableArgs =
    String


argsToString : Platform -> CursorMode -> SchemaName -> String -> String -> Int -> DetailsSidebar.Selected -> Bool -> Bool -> Bool -> Bool -> TableArgs
argsToString platform cursorMode defaultSchema openedDropdown openedPopover index selected isHover dragging virtualRelation useBasicTypes =
    [ Platform.toString platform, CursorMode.toString cursorMode, defaultSchema, openedDropdown, openedPopover, String.fromInt index, selected, B.cond isHover "Y" "N", B.cond dragging "Y" "N", B.cond virtualRelation "Y" "N", B.cond useBasicTypes "Y" "N" ] |> String.join "~"


stringToArgs : TableArgs -> ( ( Platform, CursorMode, SchemaName ), ( ( String, String, Int ), DetailsSidebar.Selected ), ( ( Bool, Bool ), ( Bool, Bool ) ) )
stringToArgs args =
    case args |> String.split "~" of
        [ platform, cursorMode, defaultSchema, openedDropdown, openedPopover, index, selected, isHover, dragging, virtualRelation, useBasicTypes ] ->
            ( ( Platform.fromString platform, CursorMode.fromString cursorMode, defaultSchema )
            , ( ( openedDropdown, openedPopover, String.toInt index |> Maybe.withDefault 0 ), selected )
            , ( ( isHover == "Y", dragging == "Y" ), ( virtualRelation == "Y", useBasicTypes == "Y" ) )
            )

        _ ->
            ( ( Platform.PC, CursorMode.Drag, Conf.schema.empty ), ( ( "", "", 0 ), "" ), ( ( False, False ), ( False, False ) ) )


viewTable : ErdConf -> ZoomLevel -> TableArgs -> ErdLayout -> TableMeta -> ErdTableLayout -> ErdTable -> Html Msg
viewTable conf zoom args layout meta tableLayout table =
    let
        ( ( platform, cursorMode, defaultSchema ), ( ( openedDropdown, openedPopover, index ), selected ), ( ( isHover, dragging ), ( virtualRelation, useBasicTypes ) ) ) =
            stringToArgs args

        ( columns, hiddenColumns ) =
            table.columns |> Dict.values |> List.map (\c -> buildColumn useBasicTypes meta tableLayout c) |> List.partition (\c -> tableLayout.columns |> ErdColumnProps.member c.path)

        dragAttrs : List (Attribute Msg)
        dragAttrs =
            B.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ onPointerDown (handleTablePointerDown table.htmlId) platform ]

        dropdown : Html Msg
        dropdown =
            TableContextMenu.view platform conf defaultSchema layout index table tableLayout.props meta.notes

        ( selectedTable, selectedColumn ) =
            case selected |> String.split "." of
                schemaName :: tableName :: columnPathStr :: [] ->
                    B.cond (schemaName == table.schema && tableName == table.name) ( True, [ ColumnPath.fromString columnPathStr ] ) ( False, [] )

                schemaName :: tableName :: [] ->
                    B.cond (schemaName == table.schema && tableName == table.name) ( True, [] ) ( False, [] )

                _ ->
                    ( False, [] )
    in
    div ([ css [ "select-none absolute" ], classList [ ( "z-max", tableLayout.props.selected ), ( "invisible", tableLayout.props.size == Size.zeroCanvas ) ] ] ++ Position.stylesGrid tableLayout.props.position ++ dragAttrs)
        [ Table.table
            { id = table.htmlId
            , ref = { schema = table.schema, table = table.name }
            , label = table.label
            , isView = table.view
            , comment = table.comment |> Maybe.map .text
            , notes = meta.notes
            , isDeprecated = meta.tags |> List.member Tag.deprecated
            , columns = tableLayout.columns |> ErdColumnProps.flatten |> List.filterMap (\c -> columns |> List.findBy .path c.path)
            , hiddenColumns = hiddenColumns |> List.sortBy .index
            , dropdown = Just dropdown
            , state =
                { color = tableLayout.props.color
                , isHover = isHover
                , highlightedColumns = tableLayout.columns |> ErdColumnProps.flatten |> List.filter .highlighted |> List.map .path |> List.append selectedColumn |> List.map ColumnPath.toString |> Set.fromList
                , selected = tableLayout.props.selected || selectedTable
                , dragging = dragging
                , collapsed = tableLayout.props.collapsed
                , openedDropdown = openedDropdown
                , openedPopover = openedPopover
                , showHiddenColumns = tableLayout.props.showHiddenColumns
                }
            , actions =
                { hover = ToggleHoverTable table.id
                , headerClick = \e -> B.cond (e.button == MainButton) (SelectItem (TableId.toHtmlId table.id) (e.ctrl || e.shift)) (Noop "non-main-button-table-header-click")
                , headerDblClick = DetailsSidebarMsg (DetailsSidebar.ShowTable table.id)
                , headerRightClick = ContextMenuCreate dropdown
                , headerDropdownClick = DropdownToggle
                , columnHover = \col on -> ToggleHoverColumn { table = table.id, column = col } on
                , columnClick = B.maybe virtualRelation (\col e -> VirtualRelationMsg (VRUpdate { table = table.id, column = col } e.clientPos))
                , columnDblClick = \col -> { table = table.id, column = col } |> DetailsSidebar.ShowColumn |> DetailsSidebarMsg
                , columnRightClick = \i col -> ContextMenuCreate (B.cond (tableLayout.columns |> ErdColumnProps.member col) ColumnContextMenu.view ColumnContextMenu.viewHidden platform i { table = table.id, column = col } (table |> ErdTable.getColumn col) (meta.columns |> ColumnPath.get col |> Maybe.andThen .notes))
                , notesClick = \col -> NotesMsg (NOpen table.id col)
                , relationsIconClick =
                    \cols isOut ->
                        Just (B.cond isOut (PlaceRight tableLayout.props.position tableLayout.props.size) (PlaceLeft tableLayout.props.position))
                            |> (\hint ->
                                    case cols of
                                        [] ->
                                            Noop "No table to show"

                                        col :: [] ->
                                            ShowTable ( col.column.schema, col.column.table ) hint

                                        _ ->
                                            ShowTables (cols |> List.map (\col -> ( col.column.schema, col.column.table ))) hint
                               )
                , nestedIconClick = ToggleNestedColumn table.id
                , hiddenColumnsHover = \id on -> PopoverOpen (B.cond on id "")
                , hiddenColumnsClick = ToggleHiddenColumns table.id
                }
            , zoom = zoom
            , conf = { layout = conf.layout, move = conf.move, select = conf.select, hover = conf.hover }
            , platform = platform
            , defaultSchema = defaultSchema
            }
        ]


handleTablePointerDown : HtmlId -> PointerEvent -> Msg
handleTablePointerDown htmlId e =
    if e.button == MainButton then
        e |> .clientPos |> DragStart htmlId

    else if e.button == MiddleButton then
        e |> .clientPos |> DragStart Conf.ids.erd

    else
        Noop "No match on table pointer down"


buildColumn : Bool -> TableMeta -> ErdTableLayout -> ErdColumn -> Table.Column
buildColumn useBasicTypes tableMeta layout column =
    let
        columnMeta : Maybe ColumnMeta
        columnMeta =
            tableMeta.columns |> ColumnPath.get column.path
    in
    { index = column.index
    , path = column.path
    , kind =
        if useBasicTypes then
            column.kindLabel |> ColumnType.asBasic

        else
            column.kindLabel
    , kindDetails =
        column.customType
            |> Maybe.map
                (\t ->
                    case t.value of
                        CustomTypeValue.Enum values ->
                            "Enum: " ++ String.join ", " values

                        CustomTypeValue.Definition definition ->
                            "Type: " ++ definition
                )
    , nullable = column.nullable
    , default = column.defaultLabel
    , comment = column.comment |> Maybe.map .text
    , notes = columnMeta |> Maybe.andThen .notes
    , isPrimaryKey = column.isPrimaryKey
    , inRelations = column.inRelations |> List.map (buildColumnRelation layout)
    , outRelations = column.outRelations |> List.map (buildColumnRelation layout)
    , uniques = column.uniques |> List.map (\u -> { name = u })
    , indexes = column.indexes |> List.map (\i -> { name = i })
    , checks = column.checks |> List.map (\c -> { name = c })
    , isDeprecated = (tableMeta.tags |> List.member Tag.deprecated) || (columnMeta |> Maybe.any (.tags >> List.member Tag.deprecated))
    , children =
        column.columns
            |> Maybe.map
                (\(ErdNestedColumns cols) ->
                    layout.columns
                        |> ErdColumnProps.find column.path
                        |> Maybe.mapOrElse ErdColumnProps.children []
                        |> List.filterMap (\p -> cols |> Ned.get p.name)
                        |> List.map (\c -> buildColumn useBasicTypes tableMeta layout c)
                        |> Table.NestedColumns (cols |> Ned.size)
                )
    }


buildColumnRelation : ErdTableLayout -> ErdColumnRef -> Table.Relation
buildColumnRelation layout relation =
    { column = { schema = relation.table |> Tuple.first, table = relation.table |> Tuple.second, column = relation.column }
    , nullable = relation.nullable
    , tableShown = layout.relatedTables |> Dict.get relation.table |> Maybe.mapOrElse .shown False
    }
