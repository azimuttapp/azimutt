module PagesComponents.Organization_.Project_.Views.Modals.TableRowContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu exposing (ItemAction, MenuItem)
import Conf
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Platform exposing (Platform)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)


view : msg -> (TableId -> Maybe ColumnPath -> msg) -> msg -> msg -> msg -> Platform -> ErdConf -> SchemaName -> TableRow -> Maybe Notes -> Html msg
view refresh openNotes collapse expand delete platform conf defaultSchema row notes =
    div [ class "z-max" ]
        ([ div [ class "px-4 py-1 text-sm font-medium leading-6 text-gray-500" ] [ text (TableId.show defaultSchema row.query.table ++ " row") ] ]
            ++ ([ Maybe.when conf.layout { label = B.cond row.selected "Refresh selected rows" "Refresh data", content = ContextMenu.Simple { action = refresh } }
                , Maybe.when conf.layout { label = notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes", content = ContextMenu.SimpleHotkey { action = openNotes row.query.table Nothing, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "notes" [] } }
                , Maybe.when conf.layout
                    { label = B.cond row.collapsed (B.cond row.selected "Expand selected tables" "Expand table") (B.cond row.selected "Collapse selected tables" "Collapse table")
                    , content = ContextMenu.SimpleHotkey { action = B.cond row.collapsed expand collapse, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "collapse" [] }
                    }
                , Maybe.when conf.layout { label = B.cond row.selected "Delete selected rows" "Delete row", content = ContextMenu.SimpleHotkey { action = delete, platform = platform, hotkeys = Conf.hotkeys |> Dict.getOrElse "hide" [] } }
                ]
                    |> List.filterMap identity
                    |> List.map ContextMenu.btnSubmenu
               )
        )
