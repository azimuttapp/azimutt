module PagesComponents.Projects.Id_.Views.Navbar.Search exposing (NavbarSearch, viewNavbarSearch)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import Html.Styled exposing (Html, div, input, label, text)
import Html.Styled.Attributes exposing (css, for, id, name, placeholder, type_)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColorLevel(..), TwColorPosition(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias NavbarSearch =
    { id : HtmlId
    }


viewNavbarSearch : Theme -> NavbarSearch -> Html msg
viewNavbarSearch theme search =
    div [ css [ Tw.ml_6 ] ]
        [ div [ css [ Tw.max_w_lg, Tw.w_full, Bp.lg [ Tw.max_w_xs ] ] ]
            [ label [ for search.id, css [ Tw.sr_only ] ] [ text "Search" ]
            , div [ css [ Tw.relative ] ]
                [ div [ css [ Tw.pointer_events_none, Tw.absolute, Tw.inset_y_0, Tw.left_0, Tw.pl_3, Tw.flex, Tw.items_center ] ] [ Icon.solid Search [ TwColor.render Text theme.color L200 ] ]
                , input
                    [ type_ "search"
                    , name "search"
                    , id search.id
                    , placeholder "Search"
                    , css
                        [ Tw.block
                        , Tw.w_full
                        , Tw.pl_10
                        , Tw.pr_3
                        , Tw.py_2
                        , Tw.border
                        , Tw.border_transparent
                        , Tw.rounded_md
                        , Tw.leading_5
                        , TwColor.render Bg theme.color L500
                        , TwColor.render Text theme.color L100
                        , TwColor.render Placeholder theme.color L200
                        , Css.focus [ Tw.outline_none, Tw.bg_white, Tw.border_white, Tw.ring_white, TwColor.render Text theme.color L900, TwColor.render Placeholder theme.color L400 ]
                        , Bp.sm [ Tw.text_sm ]
                        ]
                    ]
                    []
                ]
            ]
        ]
