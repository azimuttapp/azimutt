module Libs.Tuple3 exposing (apply, first, mapFirst, mapSecond, mapThird, new, second, third)


new : a -> b -> c -> ( a, b, c )
new a b c =
    ( a, b, c )


apply : (a -> b -> c -> d) -> ( a, b, c ) -> d
apply f ( a, b, c ) =
    f a b c


first : ( a, b, c ) -> a
first ( a, _, _ ) =
    a


second : ( a, b, c ) -> b
second ( _, b, _ ) =
    b


third : ( a, b, c ) -> c
third ( _, _, c ) =
    c


mapFirst : (a -> x) -> ( a, b, c ) -> ( x, b, c )
mapFirst f ( a, b, c ) =
    ( f a, b, c )


mapSecond : (b -> x) -> ( a, b, c ) -> ( a, x, c )
mapSecond f ( a, b, c ) =
    ( a, f b, c )


mapThird : (c -> x) -> ( a, b, c ) -> ( a, b, x )
mapThird f ( a, b, c ) =
    ( a, b, f c )
