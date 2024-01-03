module Libs.Tuple3 exposing (apply, build, first, map, mapFirst, mapSecond, mapThird, new, second, setFirst, setSecond, setThird, third)


new : a -> b -> c -> ( a, b, c )
new a b c =
    ( a, b, c )


build : b -> c -> a -> ( a, b, c )
build b c a =
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


setFirst : x -> ( a, b, c ) -> ( x, b, c )
setFirst x ( _, b, c ) =
    ( x, b, c )


setSecond : x -> ( a, b, c ) -> ( a, x, c )
setSecond x ( a, _, c ) =
    ( a, x, c )


setThird : x -> ( a, b, c ) -> ( a, b, x )
setThird x ( a, b, _ ) =
    ( a, b, x )


mapFirst : (a -> x) -> ( a, b, c ) -> ( x, b, c )
mapFirst f ( a, b, c ) =
    ( f a, b, c )


mapSecond : (b -> x) -> ( a, b, c ) -> ( a, x, c )
mapSecond f ( a, b, c ) =
    ( a, f b, c )


mapThird : (c -> x) -> ( a, b, c ) -> ( a, b, x )
mapThird f ( a, b, c ) =
    ( a, b, f c )


map : (x -> y) -> ( x, x, x ) -> ( y, y, y )
map f ( a, b, c ) =
    ( f a, f b, f c )
