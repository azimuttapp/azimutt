module PagesComponents.Organization_.Project_.Views.Erd.Table exposing (TableArgs, argsToString, stringToArgs, viewTable)

import Components.Organisms.Table as Table
import Conf
import Dict
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (classList)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.Html.Events exposing (PointerEvent, stopPointerDown)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.Nel as Nel exposing (Nel)
import Models.Position as Position
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType
import Models.Project.CustomTypeValue as CustomTypeValue
import Models.Project.SchemaName exposing (SchemaName)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn, ErdNestedColumns(..))
import PagesComponents.Organization_.Project_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableNotes exposing (ErdTableNotes)
import PagesComponents.Organization_.Project_.Models.Notes as NoteRef
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


viewTable : ErdConf -> ZoomLevel -> TableArgs -> ErdTableNotes -> ErdTableLayout -> ErdTable -> Html Msg
viewTable conf zoom args notes layout table =
    let
        ( ( platform, cursorMode, defaultSchema ), ( ( openedDropdown, openedPopover, index ), selected ), ( ( isHover, dragging ), ( virtualRelation, useBasicTypes ) ) ) =
            stringToArgs args

        ( columns, hiddenColumns ) =
            table.columns |> Dict.values |> List.map (\c -> buildColumn useBasicTypes notes layout (ColumnPath.fromName c.name) c) |> List.partition (\c -> layout.columns |> List.memberBy .name c.name)

        drag : List (Attribute Msg)
        drag =
            B.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ stopPointerDown platform (handleTablePointerDown table.htmlId) ]

        dropdown : Html Msg
        dropdown =
            TableContextMenu.view platform conf index table layout notes.table

        ( selectedTable, selectedColumn ) =
            case selected |> String.split "." of
                schemaName :: tableName :: columnName :: [] ->
                    B.cond (schemaName == table.schema && tableName == table.name) ( True, [ columnName ] ) ( False, [] )

                schemaName :: tableName :: [] ->
                    B.cond (schemaName == table.schema && tableName == table.name) ( True, [] ) ( False, [] )

                _ ->
                    ( False, [] )
    in
    div ([ css [ "select-none absolute" ], classList [ ( "z-max", layout.props.selected ), ( "invisible", layout.props.size == Size.zeroCanvas ) ] ] ++ Position.stylesGrid layout.props.position ++ drag)
        [ Table.table
            { id = table.htmlId
            , ref = { schema = table.schema, table = table.name }
            , label = table.label
            , isView = table.view
            , comment = table.comment |> Maybe.map .text
            , notes = notes.table
            , columns = layout.columns |> List.filterMap (\c -> columns |> List.findBy .name c.name)
            , hiddenColumns = hiddenColumns |> List.sortBy .index
            , dropdown = Just dropdown
            , state =
                { color = layout.props.color
                , isHover = isHover
                , highlightedColumns = layout.columns |> List.filter .highlighted |> List.map .name |> List.append selectedColumn |> Set.fromList
                , selected = layout.props.selected || selectedTable
                , dragging = dragging
                , collapsed = layout.props.collapsed
                , openedDropdown = openedDropdown
                , openedPopover = openedPopover
                , showHiddenColumns = layout.props.showHiddenColumns
                }
            , actions =
                { hover = ToggleHoverTable table.id
                , headerClick = \e -> B.cond (e.button == MainButton) (SelectTable table.id (e.ctrl || e.shift)) (Noop "non-main-button-table-header-click")
                , headerDblClick = DetailsSidebarMsg (DetailsSidebar.ShowTable table.id)
                , headerRightClick = ContextMenuCreate dropdown
                , headerDropdownClick = DropdownToggle
                , columnHover = \col on -> ToggleHoverColumn { table = table.id, column = col } on
                , columnClick = B.maybe virtualRelation (\col e -> VirtualRelationMsg (VRUpdate { table = table.id, column = col } e.clientPos))
                , columnDblClick = \col -> { table = table.id, column = col } |> DetailsSidebar.ShowColumn |> DetailsSidebarMsg
                , columnRightClick = \i col -> ContextMenuCreate (B.cond (layout.columns |> List.memberBy .name col) ColumnContextMenu.view ColumnContextMenu.viewHidden platform i { table = table.id, column = col } (notes.columns |> Dict.get col))
                , notesClick = \col -> NotesMsg (NOpen (col |> Maybe.mapOrElse (\c -> NoteRef.fromColumn { table = table.id, column = c }) (NoteRef.fromTable table.id)))
                , relationsIconClick =
                    \cols isOut ->
                        Just (B.cond isOut (PlaceRight layout.props.position layout.props.size) (PlaceLeft layout.props.position))
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
                , hiddenColumnsHover = \id on -> PopoverSet (B.cond on id "")
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


buildColumn : Bool -> ErdTableNotes -> ErdTableLayout -> ColumnPath -> ErdColumn -> Table.Column
buildColumn useBasicTypes notes layout path column =
    { index = column.index
    , path = path
    , name = column.name
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
    , notes = notes.columns |> Dict.get (path |> ColumnPath.key)
    , isPrimaryKey = column.isPrimaryKey
    , inRelations = column.inRelations |> List.map (buildColumnRelation layout)
    , outRelations = column.outRelations |> List.map (buildColumnRelation layout)
    , uniques = column.uniques |> List.map (\u -> { name = u })
    , indexes = column.indexes |> List.map (\i -> { name = i })
    , checks = column.checks |> List.map (\c -> { name = c })
    , children =
        column.columns
            |> Maybe.map
                (\(ErdNestedColumns cols) ->
                    cols
                        |> Ned.values
                        |> Nel.toList
                        |> List.filter (\c -> layout.columns |> List.any (\l -> l.name == (path |> ColumnPath.child c.name |> ColumnPath.key)))
                        |> List.map (\c -> buildColumn useBasicTypes notes layout (path |> ColumnPath.child c.name) c)
                        |> Table.NestedColumns (cols |> Ned.size)
                )
    }


buildColumnRelation : ErdTableLayout -> ErdColumnRef -> Table.Relation
buildColumnRelation layout relation =
    { column = { schema = relation.table |> Tuple.first, table = relation.table |> Tuple.second, column = relation.column }
    , nullable = relation.nullable
    , tableShown = layout.relatedTables |> Dict.get relation.table |> Maybe.mapOrElse .shown False
    }
