module PagesComponents.Organization_.Project_.Views.Modals.GroupContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Components.Organisms.ColorPicker as ColorPicker
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Libs.Models.Platform exposing (Platform)
import Models.Project.Group exposing (Group)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId
import PagesComponents.Organization_.Project_.Models exposing (GroupMsg(..), Msg(..))


view : Platform -> SchemaName -> Int -> Group -> Html Msg
view platform defaultSchema index group =
    div [ class "z-max" ]
        ([ div [ class "px-4 py-1 text-sm font-medium leading-6 text-gray-500" ] [ text (group.name ++ " group") ] ]
            ++ ([ { label = "Edit group", action = ContextMenu.Simple { action = GEdit index group.name |> GroupMsg, platform = platform, hotkeys = [] } }
                , { label = "Set color", action = ContextMenu.Custom (ColorPicker.view (GSetColor index >> GroupMsg)) }
                , { label = "Remove table", action = ContextMenu.SubMenu (group.tables |> List.map (\id -> { label = TableId.show defaultSchema id, action = GRemoveTables index [ id ] |> GroupMsg, platform = platform, hotkeys = [] })) }
                , { label = "Delete group", action = ContextMenu.Simple { action = GDelete index |> GroupMsg, platform = platform, hotkeys = [] } }
                ]
                    |> List.map ContextMenu.btnSubmenu
               )
        )
