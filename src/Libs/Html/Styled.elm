module Libs.Html.Styled exposing (bText, extLink, sendTweet)

import Html.Styled exposing (Attribute, Html, a, b, text)
import Html.Styled.Attributes exposing (href, rel, target)
import Libs.Html.Styled.Attributes exposing (track)
import Tracking exposing (events)
import Url exposing (percentEncode)


extLink : String -> List (Attribute msg) -> List (Html msg) -> Html msg
extLink url attrs children =
    a ([ href url, target "_blank", rel "noopener" ] ++ track (events.externalLink url) ++ attrs) children


sendTweet : String -> List (Attribute msg) -> List (Html msg) -> Html msg
sendTweet tweet attrs children =
    "https://twitter.com/intent/tweet?text=" ++ percentEncode tweet |> (\url -> extLink url attrs children)


bText : String -> Html msg
bText content =
    b [] [ text content ]
