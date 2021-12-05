module Components.Atoms.Badge exposing (basic, doc, rounded)

import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Attribute, Html, span, text)
import Html.Styled.Attributes exposing (css)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor, TwColorLevel(..), TwColorPosition(..))
import Tailwind.Utilities as Tw


basic : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
basic color attrs content =
    span ([ css [ Tw.inline_flex, Tw.items_center, Tw.px_2_dot_5, Tw.py_0_dot_5, Tw.rounded_full, Tw.text_xs, Tw.font_medium, TwColor.render Bg color L100, TwColor.render Text color L800 ] ] ++ attrs) content


rounded : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
rounded color attrs content =
    span ([ css [ Tw.inline_flex, Tw.items_center, Tw.px_2, Tw.py_0_dot_5, Tw.rounded, Tw.text_xs, Tw.font_medium, TwColor.render Bg color L100, TwColor.render Text color L800 ] ] ++ attrs) content



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    chapter "Badge"
        |> renderComponentList
            [ ( "basic", basic theme.color [] [ text "Badge" ] )
            , ( "rounded", rounded theme.color [] [ text "Badge" ] )
            ]
