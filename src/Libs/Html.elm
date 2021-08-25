module Libs.Html exposing (bText, codeText, divIf)

import Html exposing (Attribute, Html, b, code, div, text)


bText : String -> Html msg
bText content =
    b [] [ text content ]


codeText : String -> Html msg
codeText content =
    code [] [ text content ]


divIf : Bool -> List (Attribute msg) -> List (Html msg) -> Html msg
divIf predicate attrs children =
    if predicate then
        div attrs children

    else
        div [] []
