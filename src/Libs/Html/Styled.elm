module Libs.Html.Styled exposing (bText, extLink)

import Html.Styled exposing (Attribute, Html, a, b, text)
import Html.Styled.Attributes exposing (href, rel, target)
import Libs.Html.Styled.Attributes exposing (track)


extLink : String -> List (Attribute msg) -> List (Html msg) -> Html msg
extLink url attrs children =
    a ([ href url, target "_blank", rel "noopener" ] ++ track { name = "external-link", details = [ ( "url", url ) ] } ++ attrs) children


bText : String -> Html msg
bText content =
    b [] [ text content ]
