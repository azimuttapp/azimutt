module Libs.Models.Size exposing (Size, SizeLike, decode, diff, div, encode, fromTuple, mult, ratio, round, styles, sub, toString, toStringRound, toTuple, zero)

import Html exposing (Attribute)
import Html.Attributes exposing (style)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.Delta exposing (Delta)


type alias Size =
    { width : Float, height : Float }


type alias SizeLike x =
    { x | width : Float, height : Float }


zero : Size
zero =
    { width = 0, height = 0 }


fromTuple : ( Float, Float ) -> Size
fromTuple ( width, height ) =
    Size width height


toTuple : Size -> ( Float, Float )
toTuple size =
    ( size.width, size.height )


mult : Float -> Size -> Size
mult factor size =
    Size (size.width * factor) (size.height * factor)


div : Float -> Size -> Size
div factor size =
    Size (size.width / factor) (size.height / factor)


sub : Float -> Size -> Size
sub amount size =
    Size (size.width - amount) (size.height - amount)


diff : Size -> Size -> Delta
diff b a =
    Delta (a.width - b.width) (a.height - b.height)


ratio : Size -> Size -> Delta
ratio b a =
    Delta (a.width / b.width) (a.height / b.height)


round : Size -> Size
round size =
    Size (size.width |> Basics.round |> Basics.toFloat) (size.height |> Basics.round |> Basics.toFloat)


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


styles : Size -> List (Attribute msg)
styles size =
    [ style "width" (String.fromFloat size.width ++ "px"), style "height" (String.fromFloat size.height ++ "px") ]
