module PagesComponents.Projects.Id_.Views.Erd.Table exposing (TableArgs, argsToString, stringToArgs, viewTable)

import Components.Molecules.ContextMenu exposing (ItemAction(..))
import Components.Organisms.Table as Table
import Conf
import DataSources.SqlParser.Parsers.ColumnType as ColumnType
import Dict
import Html exposing (Attribute, Html, button, div)
import Html.Attributes exposing (style, tabindex, title, type_)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (css, role)
import Libs.Html.Events exposing (PointerEvent, stopPointerDown)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Tailwind as Color exposing (bg_500, focus, hover)
import Models.ColumnOrder as ColumnOrder
import Models.Project.SchemaName exposing (SchemaName)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), Msg(..), NotesMsg(..), VirtualRelationMsg(..))
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Projects.Id_.Models.ErdTableNotes exposing (ErdTableNotes)
import PagesComponents.Projects.Id_.Models.HideColumns as HideColumns
import PagesComponents.Projects.Id_.Models.Notes as NoteRef
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Projects.Id_.Models.ShowColumns as ShowColumns
import PagesComponents.Projects.Id_.Views.Modals.ColumnContextMenu exposing (viewColumnContextMenu, viewHiddenColumnContextMenu)
import Set


type alias TableArgs =
    String


argsToString : Platform -> CursorMode -> SchemaName -> String -> String -> Int -> Bool -> Bool -> Bool -> Bool -> TableArgs
argsToString platform cursorMode defaultSchema openedDropdown openedPopover index isHover dragging virtualRelation useBasicTypes =
    [ Platform.toString platform, CursorMode.toString cursorMode, defaultSchema, openedDropdown, openedPopover, String.fromInt index, B.cond isHover "Y" "N", B.cond dragging "Y" "N", B.cond virtualRelation "Y" "N", B.cond useBasicTypes "Y" "N" ] |> String.join "~"


stringToArgs : TableArgs -> ( ( Platform, CursorMode, SchemaName ), ( String, String, Int ), ( ( Bool, Bool ), ( Bool, Bool ) ) )
stringToArgs args =
    case args |> String.split "~" of
        [ platform, cursorMode, defaultSchema, openedDropdown, openedPopover, index, isHover, dragging, virtualRelation, useBasicTypes ] ->
            ( ( Platform.fromString platform, CursorMode.fromString cursorMode, defaultSchema )
            , ( openedDropdown, openedPopover, String.toInt index |> Maybe.withDefault 0 )
            , ( ( isHover == "Y", dragging == "Y" ), ( virtualRelation == "Y", useBasicTypes == "Y" ) )
            )

        _ ->
            ( ( Platform.PC, CursorMode.Drag, Conf.schema.default ), ( "", "", 0 ), ( ( False, False ), ( False, False ) ) )


viewTable : ErdConf -> ZoomLevel -> TableArgs -> ErdTableNotes -> ErdTableLayout -> ErdTable -> Html Msg
viewTable conf zoom args notes layout table =
    let
        ( ( platform, cursorMode, defaultSchema ), ( openedDropdown, openedPopover, index ), ( ( isHover, dragging ), ( virtualRelation, useBasicTypes ) ) ) =
            stringToArgs args

        ( columns, hiddenColumns ) =
            table.columns |> Dict.values |> List.map (buildColumn useBasicTypes notes layout) |> List.partition (\c -> layout.columns |> List.memberBy .name c.name)

        drag : List (Attribute Msg)
        drag =
            B.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ stopPointerDown platform (handleTablePointerDown table.htmlId) ]

        zIndex : Int
        zIndex =
            Conf.canvas.zIndex.tables + index + B.cond (layout.props.selected || dragging || (openedDropdown |> String.startsWith table.htmlId)) 1000 0
    in
    div
        ([ css [ "select-none absolute", B.cond (layout.props.size == Size.zero) "invisible" "" ]
         , style "left" (String.fromFloat layout.props.position.left ++ "px")
         , style "top" (String.fromFloat layout.props.position.top ++ "px")
         , style "z-index" (String.fromInt zIndex)
         ]
            ++ drag
        )
        [ Table.table
            { id = table.htmlId
            , ref = { schema = table.schema, table = table.name }
            , label = table.label
            , isView = table.view
            , comment = table.comment |> Maybe.map .text
            , notes = notes.table
            , columns = layout.columns |> List.filterMap (\c -> columns |> List.findBy .name c.name)
            , hiddenColumns = hiddenColumns |> List.sortBy .index
            , settings =
                [ Maybe.when conf.layout { label = B.cond layout.props.selected "Hide selected tables" "Hide table", action = Simple { action = HideTable table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "remove" [] } }
                , Maybe.when conf.layout
                    { label =
                        if layout.props.collapsed then
                            B.cond layout.props.selected "Expand selected tables" "Expand table"

                        else
                            B.cond layout.props.selected "Collapse selected tables" "Collapse table"
                    , action = Simple { action = ToggleColumns table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "collapse" [] }
                    }
                , Maybe.when conf.layout { label = "Add notes", action = Simple { action = NotesMsg (NOpen (NoteRef.fromTable table.id)), platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "notes" [] } }
                , Maybe.when conf.layout { label = "Show related", action = Simple { action = ShowRelatedTables table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "expand" [] } }
                , Maybe.when conf.layout { label = "Hide related", action = Simple { action = HideRelatedTables table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "shrink" [] } }
                , Maybe.when conf.layout
                    { label = B.cond layout.props.selected "Set color of selected tables" "Set color"
                    , action =
                        Custom
                            (div [ css [ "group-hover:grid grid-cols-6 gap-1 p-1 pl-2" ] ]
                                (Color.selectable
                                    |> List.map
                                        (\c ->
                                            button
                                                [ type_ "button"
                                                , onClick (TableColor table.id c)
                                                , title (Color.toString c)
                                                , role "menuitem"
                                                , tabindex -1
                                                , css [ "rounded-full w-6 h-6", bg_500 c, hover [ "scale-125" ], focus [ "outline-none" ] ]
                                                ]
                                                []
                                        )
                                )
                            )
                    }
                , Maybe.when conf.layout { label = B.cond layout.props.selected "Sort columns of selected tables" "Sort columns", action = SubMenu (ColumnOrder.all |> List.map (\o -> { label = ColumnOrder.show o, action = SortColumns table.id o, platform = platform, hotkeys = [] })) }
                , Maybe.when conf.layout
                    { label = B.cond layout.props.selected "Hide columns of selected tables" "Hide columns"
                    , action =
                        SubMenu
                            [ { label = "Without relation", action = HideColumns table.id HideColumns.Relations, platform = platform, hotkeys = [] }
                            , { label = "Regular ones", action = HideColumns table.id HideColumns.Regular, platform = platform, hotkeys = [] }
                            , { label = "Nullable ones", action = HideColumns table.id HideColumns.Nullable, platform = platform, hotkeys = [] }
                            , { label = "All", action = HideColumns table.id HideColumns.All, platform = platform, hotkeys = [] }
                            ]
                    }
                , Maybe.when conf.layout
                    { label = B.cond layout.props.selected "Show columns of selected tables" "Show columns"
                    , action =
                        SubMenu
                            [ { label = "With relations", action = ShowColumns table.id ShowColumns.Relations, platform = platform, hotkeys = [] }
                            , { label = "All", action = ShowColumns table.id ShowColumns.All, platform = platform, hotkeys = [] }
                            ]
                    }
                , Maybe.when conf.layout
                    { label = "Table order"
                    , action =
                        SubMenu
                            [ { label = "Bring forward", action = TableOrder table.id (index + 1), platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-forward" [] }
                            , { label = "Send backward", action = TableOrder table.id (index - 1), platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-backward" [] }
                            , { label = "Bring to front", action = TableOrder table.id 1000, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-to-top" [] }
                            , { label = "Send to back", action = TableOrder table.id 0, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-to-back" [] }
                            ]
                    }
                , Maybe.when conf.findPath { label = "Find path for this table", action = Simple { action = FindPathMsg (FPOpen (Just table.id) Nothing), platform = platform, hotkeys = [] } }
                ]
                    |> List.filterMap identity
            , platform = platform
            , state =
                { color = layout.props.color
                , isHover = isHover
                , highlightedColumns = layout.columns |> List.filter .highlighted |> List.map .name |> Set.fromList
                , selected = layout.props.selected
                , dragging = dragging
                , collapsed = layout.props.collapsed
                , openedDropdown = openedDropdown
                , openedPopover = openedPopover
                , showHiddenColumns = layout.props.showHiddenColumns
                }
            , actions =
                { hoverTable = ToggleHoverTable table.id
                , hoverColumn = \col -> ToggleHoverColumn { table = table.id, column = col }
                , clickHeader = SelectTable table.id
                , clickColumn = B.maybe virtualRelation (\col pos -> VirtualRelationMsg (VRUpdate { table = table.id, column = col } pos))
                , clickNotes = \col -> NotesMsg (NOpen (col |> Maybe.mapOrElse (\c -> NoteRef.fromColumn { table = table.id, column = c }) (NoteRef.fromTable table.id)))
                , contextMenuColumn = \i col -> ContextMenuCreate (B.cond (layout.columns |> List.memberBy .name col) viewColumnContextMenu viewHiddenColumnContextMenu platform i { table = table.id, column = col } (notes.columns |> Dict.get col))
                , dblClickColumn = \col -> { table = table.id, column = col } |> B.cond (layout.columns |> List.memberBy .name col) HideColumn ShowColumn
                , clickRelations =
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
                , clickHiddenColumns = ToggleHiddenColumns table.id
                , clickDropdown = DropdownToggle
                , setPopover = PopoverSet
                }
            , zoom = zoom
            , conf = { layout = conf.layout, move = conf.move, select = conf.select, hover = conf.hover }
            , defaultSchema = defaultSchema
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


buildColumn : Bool -> ErdTableNotes -> ErdTableLayout -> ErdColumn -> Table.Column
buildColumn useBasicTypes notes layout column =
    { index = column.index
    , name = column.name
    , kind =
        if useBasicTypes then
            column.kindLabel |> ColumnType.parse |> ColumnType.toString

        else
            column.kindLabel
    , kindDetails = column.customType |> Maybe.map .definition
    , nullable = column.nullable
    , default = column.defaultLabel
    , comment = column.comment |> Maybe.map .text
    , notes = notes.columns |> Dict.get column.name
    , isPrimaryKey = column.isPrimaryKey
    , inRelations = column.inRelations |> List.map (buildColumnRelation layout)
    , outRelations = column.outRelations |> List.map (buildColumnRelation layout)
    , uniques = column.uniques |> List.map (\u -> { name = u })
    , indexes = column.indexes |> List.map (\i -> { name = i })
    , checks = column.checks |> List.map (\c -> { name = c })
    }


buildColumnRelation : ErdTableLayout -> ErdColumnRef -> Table.Relation
buildColumnRelation layout relation =
    { column = { schema = relation.table |> Tuple.first, table = relation.table |> Tuple.second, column = relation.column }
    , nullable = relation.nullable
    , tableShown = layout.relatedTables |> Dict.get relation.table |> Maybe.mapOrElse .shown False
    }
