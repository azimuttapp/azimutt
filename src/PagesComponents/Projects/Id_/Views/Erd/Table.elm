module PagesComponents.Projects.Id_.Views.Erd.Table exposing (TableArgs, argsToString, stringToArgs, viewTable)

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
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Tailwind.Utilities as Tu
import Models.ColumnOrder as ColumnOrder
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), FindPathMsg(..), Msg(..), VirtualRelationMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (ErdColumn, ErdColumnRelation, ErdTable, ErdTableProps)
import Tailwind.Utilities as Tw


type alias TableArgs =
    String


argsToString : String -> Bool -> Bool -> TableArgs
argsToString openedDropdown dragging virtualRelation =
    openedDropdown ++ "#" ++ B.cond dragging "Y" "N" ++ "#" ++ B.cond virtualRelation "Y" "N"


stringToArgs : TableArgs -> ( String, Bool, Bool )
stringToArgs args =
    case args |> String.split "#" of
        [ openedDropdown, dragging, virtualRelation ] ->
            ( openedDropdown, dragging == "Y", virtualRelation == "Y" )

        _ ->
            ( "", False, False )


viewTable : ZoomLevel -> CursorMode -> TableArgs -> Int -> ErdTableProps -> ErdTable -> Html Msg
viewTable zoom cursorMode args index props table =
    let
        _ =
            Debug.log ("viewTable " ++ table.htmlId) args

        ( openedDropdown, dragging, virtualRelation ) =
            stringToArgs args

        ( columns, hiddenColumns ) =
            table.columns |> Ned.values |> Nel.map (buildColumn props) |> Nel.partition (\c -> props.columns |> List.any (\col -> c.name == col))

        drag : List (Attribute Msg)
        drag =
            B.cond (cursorMode == CursorDrag) [] [ stopPointerDown (.position >> DragStart table.htmlId) ]
    in
    div
        ([ css
            [ Tw.select_none
            , Tw.absolute
            , Tw.transform
            , Tu.translate_x_y props.position.left props.position.top "px"
            , Tu.z (Conf.canvas.zIndex.tables + index)
            , Tu.when (props.size == Size.zero) [ Tw.invisible ]
            ]
         ]
            ++ drag
        )
        [ Table.table
            { id = table.htmlId
            , ref = { schema = table.schema, table = table.name }
            , label = table.label
            , isView = table.view
            , columns = columns
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

                -- , hoverColumn = B.maybe (hoverColumn /= "") (ColumnRef.fromString hoverColumn |> (\ref -> { schema = ref.table |> Tuple.first, table = ref.table |> Tuple.second, column = ref.column }))
                , hoverColumns = props.hoverColumns
                , selected = props.selected
                , dragging = dragging
                , openedDropdown = openedDropdown
                , showHiddenColumns = props.hiddenColumns
                }
            , actions =
                { hoverTable = ToggleHoverTable table.id
                , hoverColumn = \col -> ToggleHoverColumn { table = table.id, column = col }
                , clickHeader = SelectTable table.id
                , clickColumn = B.maybe virtualRelation (\col pos -> VirtualRelationMsg (VRUpdate { table = table.id, column = col } pos))
                , dblClickColumn = \col -> { table = table.id, column = col } |> B.cond (props.columns |> L.has col) HideColumn ShowColumn
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


buildColumn : ErdTableProps -> ErdColumn -> Table.Column
buildColumn props column =
    { index = column.sqlIndex
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


buildColumnRelation : ErdTableProps -> ErdColumnRelation -> Table.Relation
buildColumnRelation props relation =
    { column = { schema = relation.ref.table |> Tuple.first, table = relation.ref.table |> Tuple.second, column = relation.ref.column }
    , nullable = relation.refNullable
    , tableShown = props.relatedTables |> Dict.get relation.ref.table |> M.mapOrElse .shown False
    }
