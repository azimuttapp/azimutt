module Libs.Svg.Attributes exposing (classes)

import Svg exposing (Attribute)
import Svg.Attributes exposing (class)


classes : List String -> Attribute msg
classes values =
    values |> List.map String.trim |> List.filter (\v -> v /= "") |> String.join " " |> class
