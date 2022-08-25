module Libs.Models.Position exposing (Position, add, decode, diff, distance, div, encode, min, move, negate, size, sub, toString, toStringRound, zero)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Delta as Delta exposing (Delta)
import Libs.Json.Encode as Encode
import Libs.Models.Size exposing (Size)


type alias Position =
    { left : Float, top : Float }


zero : Position
zero =
    { left = 0, top = 0 }


move : Delta -> Position -> Position
move delta position =
    Position (position.left + delta.dx) (position.top + delta.dy)


add : Position -> Position -> Position
add delta pos =
    Position (pos.left + delta.left) (pos.top + delta.top)


sub : Position -> Position -> Position
sub delta pos =
    Position (pos.left - delta.left) (pos.top - delta.top)


min : Position -> Position -> Position
min p1 p2 =
    Position (Basics.min p1.left p2.left) (Basics.min p1.top p2.top)


size : Position -> Position -> Size
size p1 p2 =
    Size (abs (p2.left - p1.left)) (abs (p2.top - p1.top))


div : Float -> Position -> Position
div factor pos =
    Position (pos.left / factor) (pos.top / factor)


negate : Position -> Position
negate pos =
    Position -pos.left -pos.top


diff : Position -> Position -> Delta
diff to from =
    ( from.left - to.left, from.top - to.top ) |> Delta.fromTuple


distance : Position -> Position -> Float
distance to from =
    diff to from |> (\{ dx, dy } -> sqrt (dx * dx + dy * dy))


toString : Position -> String
toString pos =
    "(" ++ String.fromFloat pos.left ++ ", " ++ String.fromFloat pos.top ++ ")"


toStringRound : Position -> String
toStringRound pos =
    "(" ++ String.fromInt (round pos.left) ++ ", " ++ String.fromInt (round pos.top) ++ ")"


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
