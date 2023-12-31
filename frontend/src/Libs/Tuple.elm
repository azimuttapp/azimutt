module Libs.Tuple exposing (append, apply, build, map, mapFirstT, mapSecondT, nAdd, nDiv, nSub, new, setFirst, setSecond)


new : a -> b -> ( a, b )
new a b =
    ( a, b )


build : b -> a -> ( a, b )
build b a =
    ( a, b )


apply : (a -> b -> c) -> ( a, b ) -> c
apply f ( a, b ) =
    f a b


append : c -> ( a, b ) -> ( a, b, c )
append c ( a, b ) =
    ( a, b, c )


setFirst : x -> ( a, b ) -> ( x, b )
setFirst x ( _, b ) =
    ( x, b )


setSecond : x -> ( a, b ) -> ( a, x )
setSecond x ( a, _ ) =
    ( a, x )


mapFirstT : (a -> ( x, t )) -> ( a, b ) -> ( ( x, b ), t )
mapFirstT f ( a, b ) =
    f a |> (\( x, t ) -> ( ( x, b ), t ))


mapSecondT : (b -> ( x, t )) -> ( a, b ) -> ( ( a, x ), t )
mapSecondT f ( a, b ) =
    f b |> (\( y, t ) -> ( ( a, y ), t ))


map : (a -> b) -> ( a, a ) -> ( b, b )
map f ( a, b ) =
    ( f a, f b )


nAdd : ( number, number ) -> ( number, number ) -> ( number, number )
nAdd ( dx, dy ) ( x, y ) =
    ( x + dx, y + dy )


nSub : ( number, number ) -> ( number, number ) -> ( number, number )
nSub ( dx, dy ) ( x, y ) =
    ( x - dx, y - dy )


nDiv : Float -> ( Float, Float ) -> ( Float, Float )
nDiv factor ( x, y ) =
    ( x / factor, y / factor )


listSeq : ( List a, List b ) -> List ( a, b )
listSeq ( xs, ys ) =
    List.map2 Tuple.pair xs ys
