module Components.Atoms.Styles exposing (global)

import Css.Global as Global
import Html.Styled exposing (Html)
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
        ]
