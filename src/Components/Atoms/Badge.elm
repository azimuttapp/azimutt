module Components.Atoms.Badge exposing (basic, doc)

import Css exposing (Style)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, span, text)
import Html.Styled.Attributes exposing (css)
import Tailwind.Utilities exposing (bg_gray_100, bg_red_100, font_medium, inline_flex, items_center, px_2_dot_5, py_0_dot_5, rounded_full, text_gray_800, text_red_800, text_xs)


basic : List Style -> String -> Html msg
basic styles label =
    span [ css ([ inline_flex, items_center, px_2_dot_5, py_0_dot_5, rounded_full, text_xs, font_medium, bg_gray_100, text_gray_800 ] ++ styles) ] [ text label ]


doc : Chapter x
doc =
    chapter "Badge"
        |> renderComponentList
            [ ( "basic", basic [] "Badge" )
            , ( "basic, red", basic [ bg_red_100, text_red_800 ] "Badge" )
            ]
