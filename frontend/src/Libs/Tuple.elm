module Libs.Tuple exposing (append, apply, build, mapFirstT, mapSecondT, nAdd, nDiv, nSub, new, setFirst, setSecond)


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


setFirst : v -> ( a, b ) -> ( v, b )
setFirst v ( _, b ) =
    ( v, b )


setSecond : v -> ( a, b ) -> ( a, v )
setSecond v ( a, _ ) =
    ( a, v )


mapFirstT : (a -> ( x, t )) -> ( a, b ) -> ( ( x, b ), t )
mapFirstT f ( a, b ) =
    f a |> (\( x, t ) -> ( ( x, b ), t ))


mapSecondT : (b -> ( y, t )) -> ( a, b ) -> ( ( a, y ), t )
mapSecondT f ( a, b ) =
    f b |> (\( y, t ) -> ( ( a, y ), t ))


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
