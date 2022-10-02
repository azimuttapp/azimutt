module Libs.Tuple exposing (nAdd, nDiv, nSub, new)


new : a -> b -> ( a, b )
new a b =
    ( a, b )


nAdd : ( number, number ) -> ( number, number ) -> ( number, number )
nAdd ( dx, dy ) ( x, y ) =
    ( x + dx, y + dy )


nSub : ( number, number ) -> ( number, number ) -> ( number, number )
nSub ( dx, dy ) ( x, y ) =
    ( x - dx, y - dy )


nDiv : Float -> ( Float, Float ) -> ( Float, Float )
nDiv factor ( x, y ) =
    ( x / factor, y / factor )
