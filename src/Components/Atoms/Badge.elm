module Components.Atoms.Badge exposing (basic, doc)

import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Attribute, Html, span, text)
import Html.Styled.Attributes exposing (css)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor, TwColorLevel(..), TwColorPosition(..))
import Tailwind.Utilities exposing (font_medium, inline_flex, items_center, px_2_dot_5, py_0_dot_5, rounded_full, text_xs)


basic : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
basic color attrs content =
    span ([ css [ inline_flex, items_center, px_2_dot_5, py_0_dot_5, rounded_full, text_xs, font_medium, TwColor.render Bg color L100, TwColor.render Text color L800 ] ] ++ attrs) content



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    chapter "Badge"
        |> renderComponentList
            [ ( "basic", basic theme.color [] [ text "Badge" ] )
            ]
