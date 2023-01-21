module PagesComponents.Organization_.Project_.Views.Modals.MemoContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Components.Organisms.ColorPicker as ColorPicker
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Libs.Bool as Bool
import Libs.Maybe as Maybe
import Libs.Models.Platform exposing (Platform)
import Libs.Tailwind as Tw
import PagesComponents.Organization_.Project_.Models exposing (MemoMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)


view : Platform -> ErdConf -> Memo -> Html Msg
view platform conf memo =
    div [ class "z-max" ]
        ([ Maybe.when conf.layout { label = "Delete memo", action = ContextMenu.Simple { action = MemoMsg (MDelete memo.id), platform = platform, hotkeys = [] } }
         , Maybe.when conf.layout { label = "Set memo color", action = ContextMenu.Custom (ColorPicker.view (\c -> MemoMsg (MSetColor memo.id (Bool.maybe (c /= Tw.gray) c)))) }
         ]
            |> List.filterMap identity
            |> List.map ContextMenu.btnSubmenu
        )
