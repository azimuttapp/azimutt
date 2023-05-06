module PagesComponents.Organization_.Project_.Views.Modals.GroupContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Components.Organisms.ColorPicker as ColorPicker
import Html exposing (Html, div)
import Libs.Models.Platform exposing (Platform)
import Models.Project.Group exposing (Group)
import PagesComponents.Organization_.Project_.Models exposing (GroupMsg(..), Msg(..))


view : Platform -> Int -> Group -> Html Msg
view platform index group =
    div []
        ([ { label = "Edit group", action = ContextMenu.Simple { action = GEdit index group.name |> GroupMsg, platform = platform, hotkeys = [] } }
         , { label = "Set color", action = ContextMenu.Custom (ColorPicker.view (GSetColor index >> GroupMsg)) }
         , { label = "Delete group", action = ContextMenu.Simple { action = GDelete index |> GroupMsg, platform = platform, hotkeys = [] } }
         ]
            |> List.map ContextMenu.btnSubmenu
        )
