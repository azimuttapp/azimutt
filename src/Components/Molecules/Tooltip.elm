module Components.Molecules.Tooltip exposing (doc, top)

import Components.Atoms.Button as Button
import Components.Atoms.Styles as Styles
import Css
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, span, text)
import Html.Styled.Attributes exposing (class, css)
import Libs.Models.Color as Color
import Tailwind.Utilities as Tw



-- see https://codepen.io/robstinson/pen/eYZLRdv
-- see https://tailwindcomponents.com/component/tooltip


top : String -> Html msg -> Html msg
top value content =
    div [ class "group", css [ Tw.relative, Tw.inline_flex, Tw.flex_col, Tw.items_center ] ]
        [ content
        , div [ class "group-hover-flex", css [ Tw.hidden, Tw.flex_col, Tw.items_center, Tw.absolute, Css.property "top" "-36px" ] ]
            [ span [ css [ Tw.relative, Tw.p_2, Tw.bg_black, Tw.text_white, Tw.text_xs, Tw.leading_none, Tw.whitespace_nowrap, Tw.rounded, Tw.shadow_lg ] ] [ text value ]
            , div [ css [ Tw.w_3, Tw.h_3, Tw.neg_mt_2, Tw.bg_black, Tw.transform, Tw.rotate_45 ] ] []
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Tooltip"
        |> Chapter.renderComponentList
            [ ( "tooltip", Button.primary3 Color.indigo [] [ text "Top tooltip" ] |> top "A top aligned tooltip." )
            , ( "global styles", div [] [ Styles.global, text "Global styles are needed for tooltip reveal" ] )
            ]
