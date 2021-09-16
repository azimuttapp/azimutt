module Libs.Size exposing (Size, div, fromTuple, mult, ratio, sub, toTuple)


type alias Size =
    { width : Float, height : Float }


fromTuple : ( Float, Float ) -> Size
fromTuple ( width, height ) =
    Size width height


toTuple : Size -> ( Float, Float )
toTuple pos =
    ( pos.width, pos.height )


mult : Float -> Size -> Size
mult factor size =
    Size (size.width * factor) (size.height * factor)


div : Float -> Size -> Size
div factor size =
    Size (size.width / factor) (size.height / factor)


sub : Float -> Size -> Size
sub amount size =
    Size (size.width - amount) (size.height - amount)


ratio : Size -> Size -> Size
ratio a b =
    Size (b.width / a.width) (b.height / a.height)
