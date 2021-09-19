module Libs.Tuple exposing (nAdd, nDiv, nSub)


nAdd : ( number, number ) -> ( number, number ) -> ( number, number )
nAdd ( dx, dy ) ( x, y ) =
    ( x + dx, y + dy )


nSub : ( number, number ) -> ( number, number ) -> ( number, number )
nSub ( dx, dy ) ( x, y ) =
    ( x - dx, y - dy )


nDiv : number -> ( number, number ) -> ( number, number )
nDiv factor ( x, y ) =
    ( x / factor, y / factor )
