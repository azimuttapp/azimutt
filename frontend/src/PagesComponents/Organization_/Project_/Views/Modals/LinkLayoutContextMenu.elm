module PagesComponents.Organization_.Project_.Views.Modals.LinkLayoutContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Components.Organisms.ColorPicker as ColorPicker
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Libs.Bool as Bool
import Libs.Maybe as Maybe
import Libs.Tailwind as Tw
import PagesComponents.Organization_.Project_.Models exposing (LinkMsg(..), Msg(..), promptSelect)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.LinkLayout exposing (LinkLayout)


view : ErdConf -> String -> LinkLayout -> Html Msg
view conf otherLayouts link =
    div [ class "z-max" ]
        ([ Maybe.when conf.layout { label = "Update link", content = ContextMenu.Simple { action = promptSelect "Linked layout:" (otherLayouts |> String.split "~") link.target (LLUpdate link.id >> LinkMsg) } }
         , Maybe.when conf.layout { label = "Set link color", content = ContextMenu.Custom (ColorPicker.view (\c -> LinkMsg (LLSetColor link.id (Bool.maybe (c /= Tw.gray) c)))) ContextMenu.BottomRight }
         , Maybe.when conf.layout { label = "Delete link", content = ContextMenu.Simple { action = LinkMsg (LLDelete link.id) } }
         ]
            |> List.filterMap identity
            |> List.map ContextMenu.btnSubmenu
        )
