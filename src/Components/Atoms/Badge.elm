module Components.Atoms.Badge exposing (basic, doc, rounded)

import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Attribute, Html, span, text)
import Html.Styled as Styled
import Libs.Html.Attributes exposing (css)
import Libs.Models.Color exposing (Color)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind exposing (bg_100, text_800)


basic : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
basic color attrs content =
    span ([ css [ "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", bg_100 color, text_800 color ] ] ++ attrs) content


rounded : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
rounded color attrs content =
    span ([ css [ "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium", bg_100 color, text_800 color ] ] ++ attrs) content



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    Chapter.chapter "Badge"
        |> Chapter.renderComponentList
            [ ( "basic", basic theme.color [] [ text "Badge" ] |> Styled.fromUnstyled )
            , ( "rounded", rounded theme.color [] [ text "Badge" ] |> Styled.fromUnstyled )
            ]
