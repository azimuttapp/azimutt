module Libs.Delta exposing (Delta, adjust, decode, decodeEvent, div, encode, fromTuple, mult, negate, zero)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Json.Encode as Encode
import Libs.Models.ZoomLevel exposing (ZoomLevel)


type alias Delta =
    { dx : Float, dy : Float }


zero : Delta
zero =
    { dx = 0, dy = 0 }


fromTuple : ( Float, Float ) -> Delta
fromTuple ( dx, dy ) =
    Delta dx dy


negate : Delta -> Delta
negate delta =
    Delta -delta.dx -delta.dy


mult : Float -> Delta -> Delta
mult factor pos =
    Delta (pos.dx * factor) (pos.dy * factor)


div : Float -> Delta -> Delta
div factor pos =
    Delta (pos.dx / factor) (pos.dy / factor)


adjust : ZoomLevel -> Delta -> Delta
adjust zoom delta =
    Delta (delta.dx * zoom) (delta.dy * zoom)


encode : Delta -> Value
encode value =
    Encode.notNullObject
        [ ( "dx", value.dx |> Encode.float )
        , ( "dy", value.dy |> Encode.float )
        ]


decode : Decode.Decoder Delta
decode =
    Decode.map2 Delta
        (Decode.field "dy" Decode.float)
        (Decode.field "dy" Decode.float)


decodeEvent : Decode.Decoder Delta
decodeEvent =
    Decode.map2 Delta
        (Decode.field "deltaX" Decode.float)
        (Decode.field "deltaY" Decode.float)
