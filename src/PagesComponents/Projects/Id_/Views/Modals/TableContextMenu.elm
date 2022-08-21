module PagesComponents.Projects.Id_.Views.Modals.TableContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Conf
import Html exposing (Html, button, div)
import Html.Attributes exposing (class, tabindex, title, type_)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (css, role)
import Libs.Maybe as Maybe
import Libs.Models.Platform exposing (Platform)
import Libs.Tailwind as Color exposing (bg_500, focus, hover)
import Models.ColumnOrder as ColumnOrder
import PagesComponents.Projects.Id_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), Msg(..), NotesMsg(..))
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Projects.Id_.Models.HideColumns as HideColumns
import PagesComponents.Projects.Id_.Models.Notes as NoteRef
import PagesComponents.Projects.Id_.Models.ShowColumns as ShowColumns


view : Platform -> ErdConf -> Int -> ErdTable -> ErdTableLayout -> Maybe String -> Html Msg
view platform conf index table layout notes =
    div [ class "z-max" ]
        ([ Maybe.when conf.layout { label = "Show details", action = ContextMenu.Simple { action = DetailsSidebarMsg (DetailsSidebar.ShowTable table.id), platform = platform, hotkeys = [] } }
         , Maybe.when conf.layout { label = B.cond layout.props.selected "Hide selected tables" "Hide table", action = ContextMenu.Simple { action = HideTable table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "remove" [] } }
         , Maybe.when conf.layout { label = notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes", action = ContextMenu.Simple { action = NotesMsg (NOpen (NoteRef.fromTable table.id)), platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "notes" [] } }
         , Maybe.when conf.layout
            { label = B.cond layout.props.selected "Set color of selected tables" "Set color"
            , action =
                ContextMenu.Custom
                    (div [ css [ "group-hover:grid grid-cols-6 gap-1 p-1 pl-2" ] ]
                        (Color.selectable |> List.map (\c -> button [ type_ "button", onClick (TableColor table.id c), title (Color.toString c), role "menuitem", tabindex -1, css [ "rounded-full w-6 h-6", bg_500 c, hover [ "scale-125" ], focus [ "outline-none" ] ] ] []))
                    )
            }
         , Maybe.when conf.layout { label = B.cond layout.props.selected "Sort columns of selected tables" "Sort columns", action = ContextMenu.SubMenu (ColumnOrder.all |> List.map (\o -> { label = ColumnOrder.show o, action = SortColumns table.id o, platform = platform, hotkeys = [] })) }
         , Maybe.when conf.layout
            { label = B.cond layout.props.selected "Hide columns of selected tables" "Hide columns"
            , action =
                ContextMenu.SubMenu
                    [ { label = "Without relation", action = HideColumns table.id HideColumns.Relations, platform = platform, hotkeys = [] }
                    , { label = "Regular ones", action = HideColumns table.id HideColumns.Regular, platform = platform, hotkeys = [] }
                    , { label = "Nullable ones", action = HideColumns table.id HideColumns.Nullable, platform = platform, hotkeys = [] }
                    , { label = "All", action = HideColumns table.id HideColumns.All, platform = platform, hotkeys = [] }
                    ]
            }
         , Maybe.when conf.layout
            { label = B.cond layout.props.selected "Show columns of selected tables" "Show columns"
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
         , Maybe.when conf.layout
            { label =
                if layout.props.collapsed then
                    B.cond layout.props.selected "Expand selected tables" "Expand table"

                else
                    B.cond layout.props.selected "Collapse selected tables" "Collapse table"
            , action = ContextMenu.Simple { action = ToggleColumns table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "collapse" [] }
            }
         , Maybe.when conf.layout { label = "Show related", action = ContextMenu.Simple { action = ShowRelatedTables table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "expand" [] } }
         , Maybe.when conf.layout { label = "Hide related", action = ContextMenu.Simple { action = HideRelatedTables table.id, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "shrink" [] } }
         , Maybe.when conf.findPath { label = "Find path for this table", action = ContextMenu.Simple { action = FindPathMsg (FPOpen (Just table.id) Nothing), platform = platform, hotkeys = [] } }
         ]
            |> List.filterMap identity
            |> List.map ContextMenu.btnSubmenu
        )
