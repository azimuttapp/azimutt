module Libs.Svg.Attributes exposing (css, vectorEffect)

import Html.Attributes exposing (attribute)
import Svg exposing (Attribute)
import Svg.Attributes exposing (class)


css : List String -> Attribute msg
css values =
    values |> List.map String.trim |> List.filter (\v -> v /= "") |> String.join " " |> class


vectorEffect : String -> Attribute msg
vectorEffect value =
    attribute "vector-effect" value
