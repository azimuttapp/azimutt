module Libs.Fuzz exposing (letter, listN, map6, map7, map8, map9, nel, nelN)

import Fuzz exposing (Fuzzer)
import Libs.Nel exposing (Nel)
import Random
import Shrink



-- Generic fuzzers


nel : Fuzzer a -> Fuzzer (Nel a)
nel fuzz =
    Fuzz.map2 Nel fuzz (Fuzz.list fuzz)


listN : Int -> Fuzzer a -> Fuzzer (List a)
listN n fuzzer =
    if n <= 0 then
        Fuzz.constant []

    else
        Fuzz.andMap (listN (n - 1) fuzzer) (fuzzer |> Fuzz.map (\a xs -> a :: xs))


nelN : Int -> Fuzzer a -> Fuzzer (Nel a)
nelN n fuzz =
    Fuzz.map2 Nel fuzz (listN (n - 1) fuzz)


digit : Fuzzer Char
digit =
    Fuzz.custom (Random.int 48 57 |> Random.map Char.fromCode) Shrink.character


letter : Fuzzer Char
letter =
    Fuzz.custom (Random.int 97 122 |> Random.map Char.fromCode) Shrink.character


map6 : (a -> b -> c -> d -> e -> f -> g) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g
map6 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF =
    Fuzz.map2 (\( a, b, c ) ( d, e, f ) -> transform a b c d e f)
        (Fuzz.tuple3 ( fuzzA, fuzzB, fuzzC ))
        (Fuzz.tuple3 ( fuzzD, fuzzE, fuzzF ))


map7 : (a -> b -> c -> d -> e -> f -> g -> h) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h
map7 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG =
    Fuzz.map3 (\( a, b, c ) ( d, e, f ) g -> transform a b c d e f g)
        (Fuzz.tuple3 ( fuzzA, fuzzB, fuzzC ))
        (Fuzz.tuple3 ( fuzzD, fuzzE, fuzzF ))
        fuzzG


map8 : (a -> b -> c -> d -> e -> f -> g -> h -> i) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i
map8 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH =
    Fuzz.map3 (\( a, b, c ) ( d, e, f ) ( g, h ) -> transform a b c d e f g h)
        (Fuzz.tuple3 ( fuzzA, fuzzB, fuzzC ))
        (Fuzz.tuple3 ( fuzzD, fuzzE, fuzzF ))
        (Fuzz.tuple ( fuzzG, fuzzH ))


map9 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j
map9 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI =
    Fuzz.map3 (\( a, b, c ) ( d, e, f ) ( g, h, i ) -> transform a b c d e f g h i)
        (Fuzz.tuple3 ( fuzzA, fuzzB, fuzzC ))
        (Fuzz.tuple3 ( fuzzD, fuzzE, fuzzF ))
        (Fuzz.tuple3 ( fuzzG, fuzzH, fuzzI ))
