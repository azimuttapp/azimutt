module Components.Atoms.Styles exposing (global)

import Css.Global as Global
import Html.Styled exposing (Html)
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw



{-
   Global styles
   They are needed for some components, for example:
   - tooltip hover reveal
   - dropdown submenu
-}


global : Html msg
global =
    Global.global
        [ Global.selector ".group:hover .group-hover-flex" [ Tw.flex ]
        , Global.selector ".group:hover .group-hover-block" [ Tw.block ]
        , Global.selector ".tw-cursor-hand, .tw-cursor-hand *" [ Tu.cursor_hand ]
        , Global.selector ".tw-cursor-hand-drag, .tw-cursor-hand-drag *" [ Tu.cursor_hand_drag ]
        , Global.selector ".tw-cursor-cross, .tw-cursor-cross *" [ Tu.cursor_hand_drag ]
        , Global.selector """input[type="search"]::-webkit-search-decoration,
                             input[type="search"]::-webkit-search-cancel-button,
                             input[type="search"]::-webkit-search-results-button,
                             input[type="search"]::-webkit-search-results-decoration""" [ Tw.hidden ]
        ]
