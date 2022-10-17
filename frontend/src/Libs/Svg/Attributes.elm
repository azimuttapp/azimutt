module Libs.Svg.Attributes exposing (css, vectorEffect, when)

import Html.Attributes exposing (attribute, classList)
import Libs.Html.Attributes exposing (styles)
import Libs.Tailwind exposing (TwClass)
import Svg exposing (Attribute)
import Svg.Attributes exposing (class)


css : List TwClass -> Attribute msg
css values =
    values |> styles |> class


vectorEffect : String -> Attribute msg
vectorEffect value =
    attribute "vector-effect" value


when : Bool -> Attribute msg -> Attribute msg
when p attr =
    if p then
        attr

    else
        classList []
