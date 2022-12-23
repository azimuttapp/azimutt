module Libs.Models.Position exposing (Position, decode, diff, distance, div, encode, fromTuple, min, move, mult, negate, round, size, toString, toStringRound, toTuple, zero)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.Delta exposing (Delta)
import Libs.Models.Size exposing (Size)


type alias Position =
    { left : Float, top : Float }


zero : Position
zero =
    { left = 0, top = 0 }


move : Delta -> Position -> Position
move delta position =
    Position (position.left + delta.dx) (position.top + delta.dy)


min : Position -> Position -> Position
min p1 p2 =
    Position (Basics.min p1.left p2.left) (Basics.min p1.top p2.top)


size : Position -> Position -> Size
size p1 p2 =
    Size (abs (p2.left - p1.left)) (abs (p2.top - p1.top))


mult : Float -> Position -> Position
mult factor pos =
    Position (pos.left * factor) (pos.top * factor)


div : Float -> Position -> Position
div factor pos =
    Position (pos.left / factor) (pos.top / factor)


negate : Position -> Position
negate pos =
    Position -pos.left -pos.top


diff : Position -> Position -> Delta
diff b a =
    Delta (a.left - b.left) (a.top - b.top)


round : Position -> Position
round pos =
    Position (pos.left |> Basics.round |> Basics.toFloat) (pos.top |> Basics.round |> Basics.toFloat)


distance : Position -> Position -> Float
distance b a =
    diff b a |> (\{ dx, dy } -> sqrt (dx * dx + dy * dy))


fromTuple : ( Float, Float ) -> Position
fromTuple ( left, top ) =
    Position left top


toTuple : Position -> ( Float, Float )
toTuple { left, top } =
    ( left, top )


toString : Position -> String
toString pos =
    "(" ++ String.fromFloat pos.left ++ "," ++ String.fromFloat pos.top ++ ")"


toStringRound : Position -> String
toStringRound pos =
    pos |> round |> toString


encode : Position -> Value
encode value =
    Encode.notNullObject
        [ ( "left", value.left |> Encode.float )
        , ( "top", value.top |> Encode.float )
        ]


decode : Decode.Decoder Position
decode =
    Decode.map2 Position
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)
