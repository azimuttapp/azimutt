module Libs.Html exposing (bText, codeText, divIf, extLink, none, sendTweet)

import Html exposing (Attribute, Html, a, b, code, div, text)
import Html.Attributes exposing (href, rel, target)
import Libs.Html.Attributes exposing (hrefBlank, track)
import Track
import Url exposing (percentEncode)


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


extLink : String -> List (Attribute msg) -> List (Html msg) -> Html msg
extLink url attrs children =
    a (hrefBlank url ++ track (Track.externalLink url) ++ attrs) children


none : Html msg
none =
    text ""


sendTweet : String -> List (Attribute msg) -> List (Html msg) -> Html msg
sendTweet tweet attrs children =
    "https://twitter.com/intent/tweet?text=" ++ percentEncode tweet |> (\url -> extLink url attrs children)
