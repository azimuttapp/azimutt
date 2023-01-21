module Libs.Svg.Attributes exposing (css, vectorEffect)

import Html.Attributes exposing (attribute)
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
