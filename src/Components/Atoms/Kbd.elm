module Components.Atoms.Kbd exposing (badge, doc)

import Components.Atoms.Badge as Badge
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Attribute, Html, text)
import Libs.Models.Color as Color


badge : List (Attribute msg) -> List String -> Html msg
badge attrs keys =
    Badge.rounded Color.gray attrs [ text (keys |> String.join " + ") ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Kbd"
        |> renderComponentList
            [ ( "badge", badge [] [ "Ctrl", "Alt", "S" ] ) ]
