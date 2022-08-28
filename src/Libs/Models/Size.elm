module Libs.Models.Size exposing (Size, decode, div, encode, fromTuple, mult, ratio, round, sub, toString, toStringRound, toTuple, zero)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode


type alias Size =
    { width : Float, height : Float }


zero : Size
zero =
    { width = 0, height = 0 }


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


round : Size -> Size
round delta =
    Size (delta.width |> Basics.round |> Basics.toFloat) (delta.height |> Basics.round |> Basics.toFloat)


toString : Size -> String
toString size =
    String.fromFloat size.width ++ "x" ++ String.fromFloat size.height


toStringRound : Size -> String
toStringRound size =
    size |> round |> toString


encode : Size -> Value
encode value =
    Encode.notNullObject
        [ ( "width", value.width |> Encode.float )
        , ( "height", value.height |> Encode.float )
        ]


decode : Decode.Decoder Size
decode =
    Decode.map2 Size
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
