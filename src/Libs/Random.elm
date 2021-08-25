module Libs.Random exposing (genChoose)

import Random


genChoose : ( a, List a ) -> Random.Generator a
genChoose ( item, list ) =
    Random.int 0 (list |> List.length) |> Random.map (\num -> list |> List.drop num |> List.head |> Maybe.withDefault item)
