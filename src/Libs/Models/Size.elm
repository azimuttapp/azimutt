module Libs.Models.Size exposing (Size, decode, div, encode, fromTuple, mult, ratio, sub, toTuple)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as E


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


encode : Size -> Value
encode value =
    E.object
        [ ( "width", value.width |> Encode.float )
        , ( "height", value.height |> Encode.float )
        ]


decode : Decode.Decoder Size
decode =
    Decode.map2 Size
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
