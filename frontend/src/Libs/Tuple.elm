module Libs.Tuple exposing (apply, nAdd, nDiv, nSub, new)


new : a -> b -> ( a, b )
new a b =
    ( a, b )


apply : (a -> b -> c) -> ( a, b ) -> c
apply f ( a, b ) =
    f a b


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
