module Libs.Fuzz exposing (letter, listN, map10, map11, map12, map13, map14, map15, map16, map9, nel, nelN)

import Fuzz exposing (Fuzzer)
import Libs.Nel exposing (Nel)



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
    Fuzz.intRange 48 57 |> Fuzz.map Char.fromCode


letter : Fuzzer Char
letter =
    Fuzz.intRange 97 122 |> Fuzz.map Char.fromCode


map9 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j
map9 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI =
    Fuzz.map3 (\( a, b, c ) ( d, e, f ) ( g, h, i ) -> transform a b c d e f g h i)
        (Fuzz.triple fuzzA fuzzB fuzzC)
        (Fuzz.triple fuzzD fuzzE fuzzF)
        (Fuzz.triple fuzzG fuzzH fuzzI)


map10 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j -> Fuzzer k
map10 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI fuzzJ =
    Fuzz.map4 (\( a, b, c ) ( d, e, f ) ( g, h, i ) j -> transform a b c d e f g h i j)
        (Fuzz.triple fuzzA fuzzB fuzzC)
        (Fuzz.triple fuzzD fuzzE fuzzF)
        (Fuzz.triple fuzzG fuzzH fuzzI)
        fuzzJ


map11 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j -> Fuzzer k -> Fuzzer l
map11 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI fuzzJ fuzzK =
    Fuzz.map4 (\( a, b, c ) ( d, e, f ) ( g, h, i ) ( j, k ) -> transform a b c d e f g h i j k)
        (Fuzz.triple fuzzA fuzzB fuzzC)
        (Fuzz.triple fuzzD fuzzE fuzzF)
        (Fuzz.triple fuzzG fuzzH fuzzI)
        (Fuzz.pair fuzzJ fuzzK)


map12 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j -> Fuzzer k -> Fuzzer l -> Fuzzer m
map12 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI fuzzJ fuzzK fuzzL =
    Fuzz.map4 (\( a, b, c ) ( d, e, f ) ( g, h, i ) ( j, k, l ) -> transform a b c d e f g h i j k l)
        (Fuzz.triple fuzzA fuzzB fuzzC)
        (Fuzz.triple fuzzD fuzzE fuzzF)
        (Fuzz.triple fuzzG fuzzH fuzzI)
        (Fuzz.triple fuzzJ fuzzK fuzzL)


map13 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j -> Fuzzer k -> Fuzzer l -> Fuzzer m -> Fuzzer n
map13 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI fuzzJ fuzzK fuzzL fuzzM =
    Fuzz.map5 (\( a, b, c ) ( d, e, f ) ( g, h, i ) ( j, k, l ) m -> transform a b c d e f g h i j k l m)
        (Fuzz.triple fuzzA fuzzB fuzzC)
        (Fuzz.triple fuzzD fuzzE fuzzF)
        (Fuzz.triple fuzzG fuzzH fuzzI)
        (Fuzz.triple fuzzJ fuzzK fuzzL)
        fuzzM


map14 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j -> Fuzzer k -> Fuzzer l -> Fuzzer m -> Fuzzer n -> Fuzzer o
map14 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI fuzzJ fuzzK fuzzL fuzzM fuzzN =
    Fuzz.map5 (\( a, b, c ) ( d, e, f ) ( g, h, i ) ( j, k, l ) ( m, n ) -> transform a b c d e f g h i j k l m n)
        (Fuzz.triple fuzzA fuzzB fuzzC)
        (Fuzz.triple fuzzD fuzzE fuzzF)
        (Fuzz.triple fuzzG fuzzH fuzzI)
        (Fuzz.triple fuzzJ fuzzK fuzzL)
        (Fuzz.pair fuzzM fuzzN)


map15 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o -> p) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j -> Fuzzer k -> Fuzzer l -> Fuzzer m -> Fuzzer n -> Fuzzer o -> Fuzzer p
map15 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI fuzzJ fuzzK fuzzL fuzzM fuzzN fuzzO =
    Fuzz.map5 (\( a, b, c ) ( d, e, f ) ( g, h, i ) ( j, k, l ) ( m, n, o ) -> transform a b c d e f g h i j k l m n o)
        (Fuzz.triple fuzzA fuzzB fuzzC)
        (Fuzz.triple fuzzD fuzzE fuzzF)
        (Fuzz.triple fuzzG fuzzH fuzzI)
        (Fuzz.triple fuzzJ fuzzK fuzzL)
        (Fuzz.triple fuzzM fuzzN fuzzO)


map16 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o -> p -> q) -> Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer d -> Fuzzer e -> Fuzzer f -> Fuzzer g -> Fuzzer h -> Fuzzer i -> Fuzzer j -> Fuzzer k -> Fuzzer l -> Fuzzer m -> Fuzzer n -> Fuzzer o -> Fuzzer p -> Fuzzer q
map16 transform fuzzA fuzzB fuzzC fuzzD fuzzE fuzzF fuzzG fuzzH fuzzI fuzzJ fuzzK fuzzL fuzzM fuzzN fuzzO fuzzP =
    Fuzz.map3 (\( ( a, b, c ), ( d, e, f ) ) ( ( g, h, i ), ( j, k, l ) ) ( ( m, n, o ), p ) -> transform a b c d e f g h i j k l m n o p)
        (Fuzz.pair (Fuzz.triple fuzzA fuzzB fuzzC) (Fuzz.triple fuzzD fuzzE fuzzF))
        (Fuzz.pair (Fuzz.triple fuzzG fuzzH fuzzI) (Fuzz.triple fuzzJ fuzzK fuzzL))
        (Fuzz.pair (Fuzz.triple fuzzM fuzzN fuzzO) fuzzP)
