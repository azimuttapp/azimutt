module Libs.Html exposing (bText, codeText, divIf, extLink, iText, none, sendTweet, uText)

import Html exposing (Attribute, Html, a, b, code, div, i, span, text, u)
import Html.Attributes exposing (class)
import Libs.Html.Attributes exposing (hrefBlank, track)
import Track
import Url exposing (percentEncode)


bText : String -> Html msg
bText content =
    b [] [ text content ]


iText : String -> Html msg
iText content =
    i [] [ text content ]


uText : String -> Html msg
uText content =
    span [ class "underline" ] [ text content ]


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
