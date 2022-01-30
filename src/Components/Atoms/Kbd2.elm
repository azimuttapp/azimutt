module Components.Atoms.Kbd2 exposing (badge, doc)

import Components.Atoms.Badge2 as Badge2
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Attribute, Html, text)
import Html.Styled as Styled
import Libs.Models.Color as Color


badge : List (Attribute msg) -> List String -> Html msg
badge attrs keys =
    Badge2.rounded Color.gray attrs [ text (keys |> String.join " + ") ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Kbd2"
        |> renderComponentList
            [ ( "badge", badge [] [ "Ctrl", "Alt", "S" ] |> Styled.fromUnstyled ) ]
