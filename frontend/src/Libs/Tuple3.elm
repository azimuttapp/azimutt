module Libs.Tuple3 exposing (mapFirst, mapSecond, mapThird)


mapFirst : (a -> x) -> ( a, b, c ) -> ( x, b, c )
mapFirst f ( a, b, c ) =
    ( f a, b, c )


mapSecond : (b -> x) -> ( a, b, c ) -> ( a, x, c )
mapSecond f ( a, b, c ) =
    ( a, f b, c )


mapThird : (c -> x) -> ( a, b, c ) -> ( a, b, x )
mapThird f ( a, b, c ) =
    ( a, b, f c )
