module Components.Atoms.Kbd exposing (badge, doc)

import Components.Atoms.Badge as Badge
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Attribute, Html, text)
import Libs.Tailwind as Tw


badge : List (Attribute msg) -> List String -> Html msg
badge attrs keys =
    Badge.basicFlex Tw.gray attrs [ text (keys |> String.join " + ") ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Kbd"
        |> renderComponentList
            [ ( "badge", badge [] [ "Ctrl", "Alt", "S" ] ) ]
