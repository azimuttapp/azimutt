module PagesComponents.Organization_.Project_.Views.Modals.TableContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu exposing (ItemAction, MenuItem)
import Components.Organisms.ColorPicker as ColorPicker
import Conf
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Platform exposing (Platform)
import Models.ColumnOrder as ColumnOrder
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (FindPathMsg(..), GroupMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Organization_.Project_.Models.HideColumns as HideColumns
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))
import PagesComponents.Organization_.Project_.Models.ShowColumns as ShowColumns


view : Platform -> ErdConf -> SchemaName -> ErdLayout -> Int -> ErdTable -> ErdTableProps -> Maybe Notes -> Html Msg
view platform conf defaultSchema layout index table props notes =
    div [ class "z-max" ]
        ([ div [ class "px-4 py-1 text-sm font-medium leading-6 text-gray-500" ] [ text (TableId.show defaultSchema table.id ++ " table") ] ]
            ++ ([ Maybe.when conf.layout { label = "Show details", action = ContextMenu.Simple { action = DetailsSidebarMsg (DetailsSidebar.ShowTable table.id), platform = platform, hotkeys = [] } }
                , Maybe.when conf.layout { label = B.cond props.selected "Hide selected tables" "Hide table", action = ContextMenu.Simple { action = HideTable table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "hide" [] } }
                , Maybe.when conf.layout { label = notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes", action = ContextMenu.Simple { action = NotesMsg (NOpen table.id Nothing), platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "notes" [] } }
                , Maybe.when conf.layout { label = B.cond props.selected "Set color of selected tables" "Set color", action = ContextMenu.Custom (ColorPicker.view (TableColor table.id)) }
                , Maybe.when conf.layout { label = B.cond props.selected "Sort columns of selected tables" "Sort columns", action = ContextMenu.SubMenu (ColumnOrder.all |> List.map (\o -> { label = ColumnOrder.show o, action = SortColumns table.id o, platform = platform, hotkeys = [] })) }
                , Maybe.when conf.layout
                    { label = B.cond props.selected "Hide columns of selected tables" "Hide columns"
                    , action =
                        ContextMenu.SubMenu
                            [ { label = "Without relation", action = HideColumns table.id HideColumns.Relations, platform = platform, hotkeys = [] }
                            , { label = "Regular ones", action = HideColumns table.id HideColumns.Regular, platform = platform, hotkeys = [] }
                            , { label = "Nullable ones", action = HideColumns table.id HideColumns.Nullable, platform = platform, hotkeys = [] }
                            , { label = "All", action = HideColumns table.id HideColumns.All, platform = platform, hotkeys = [] }
                            ]
                    }
                , Maybe.when conf.layout
                    { label = B.cond props.selected "Show columns of selected tables" "Show columns"
                    , action =
                        ContextMenu.SubMenu
                            [ { label = "With relations", action = ShowColumns table.id ShowColumns.Relations, platform = platform, hotkeys = [] }
                            , { label = "All", action = ShowColumns table.id ShowColumns.All, platform = platform, hotkeys = [] }
                            ]
                    }
                , Maybe.when conf.layout
                    { label = "Table order"
                    , action =
                        ContextMenu.SubMenu
                            [ { label = "Bring forward", action = TableOrder table.id (index + 1), platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-forward" [] }
                            , { label = "Send backward", action = TableOrder table.id (index - 1), platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-backward" [] }
                            , { label = "Bring to front", action = TableOrder table.id 1000, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-to-top" [] }
                            , { label = "Send to back", action = TableOrder table.id 0, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "move-to-back" [] }
                            ]
                    }
                , groupMenu platform layout table props
                , Maybe.when conf.layout
                    { label =
                        if props.collapsed then
                            B.cond props.selected "Expand selected tables" "Expand table"

                        else
                            B.cond props.selected "Collapse selected tables" "Collapse table"
                    , action = ContextMenu.Simple { action = ToggleColumns table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "collapse" [] }
                    }
                , Maybe.when conf.layout { label = "Show related", action = ContextMenu.Simple { action = ShowRelatedTables table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "expand" [] } }
                , Maybe.when conf.layout { label = "Hide related", action = ContextMenu.Simple { action = HideRelatedTables table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "shrink" [] } }
                , Maybe.when conf.findPath { label = "Find path from this table", action = ContextMenu.Simple { action = FindPathMsg (FPOpen (Just table.id) Nothing), platform = platform, hotkeys = [] } }
                ]
                    |> List.filterMap identity
                    |> List.map ContextMenu.btnSubmenu
               )
        )


groupMenu : Platform -> ErdLayout -> ErdTable -> ErdTableProps -> Maybe (MenuItem Msg)
groupMenu platform layout table props =
    let
        targetTables : List TableId
        targetTables =
            if props.selected then
                layout |> .tables |> List.filter (.props >> .selected) |> List.map .id

            else
                [ table.id ]
    in
    if layout.groups |> List.isEmpty then
        Just { label = "Create group", action = ContextMenu.Simple { action = GCreate targetTables |> GroupMsg, platform = platform, hotkeys = [] } }

    else
        let
            ( tableGroups, otherGroups ) =
                layout.groups |> List.zipWithIndex |> List.partition (\( g, _ ) -> g.tables |> List.member table.id)
        in
        Just
            { label = "Groups"
            , action =
                ContextMenu.SubMenu
                    ([ { label = "Create group", action = GCreate targetTables |> GroupMsg, platform = platform, hotkeys = [] } ]
                        ++ (otherGroups |> List.map (\( g, i ) -> { label = "Add to " ++ g.name, action = GAddTables i targetTables |> GroupMsg, platform = platform, hotkeys = [] }))
                        ++ (tableGroups |> List.map (\( g, i ) -> { label = "Remove from " ++ g.name, action = GRemoveTables i targetTables |> GroupMsg, platform = platform, hotkeys = [] }))
                    )
            }
