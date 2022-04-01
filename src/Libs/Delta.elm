module Libs.Delta exposing (Delta, adjust, decode, encode, fromTuple, move, negate)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Json.Encode as Encode
import Libs.Models.Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)


type alias Delta =
    { dx : Float, dy : Float }


fromTuple : ( Float, Float ) -> Delta
fromTuple ( dx, dy ) =
    Delta dx dy


negate : Delta -> Delta
negate delta =
    Delta -delta.dx -delta.dy


adjust : ZoomLevel -> Delta -> Delta
adjust zoom delta =
    Delta (delta.dx * zoom) (delta.dy * zoom)


move : Position -> Delta -> Position
move position delta =
    Position (position.left + delta.dx) (position.top + delta.dy)


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
