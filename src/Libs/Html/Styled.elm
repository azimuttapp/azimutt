module Libs.Html.Styled exposing (bText)

import Html.Styled exposing (Html, b, text)


bText : String -> Html msg
bText content =
    b [] [ text content ]
