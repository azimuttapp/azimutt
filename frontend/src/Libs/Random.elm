module Libs.Random exposing (genChoose, generate2)

import Random


genChoose : ( a, List a ) -> Random.Generator a
genChoose ( item, list ) =
    Random.int 0 (list |> List.length) |> Random.map (\num -> list |> List.drop num |> List.head |> Maybe.withDefault item)


generate2 : (a -> b -> msg) -> Random.Generator a -> Random.Generator b -> Cmd msg
generate2 tagger genA genB =
    Random.pair genA genB |> Random.generate (\( a, b ) -> tagger a b)
