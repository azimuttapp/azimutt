module Libs.Svg.Attributes exposing (css)

import Svg exposing (Attribute)
import Svg.Attributes exposing (class)


css : List String -> Attribute msg
css values =
    values |> List.map String.trim |> List.filter (\v -> v /= "") |> String.join " " |> class
