module Libs.Html exposing (bText, codeText, divIf, extLink)

import Html exposing (Attribute, Html, a, b, code, div, text)
import Html.Attributes exposing (href, rel, target)
import Libs.Html.Attributes exposing (track)
import Track


extLink : String -> List (Attribute msg) -> List (Html msg) -> Html msg
extLink url attrs children =
    a ([ href url, target "_blank", rel "noopener" ] ++ track (Track.externalLink url) ++ attrs) children


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
