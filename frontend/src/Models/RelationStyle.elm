module Models.RelationStyle exposing (RelationStyle(..), all, decode, encode, fromString, show, toString)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode


type RelationStyle
    = Bezier
    | Straight
    | Steps


all : List RelationStyle
all =
    [ Bezier, Straight, Steps ]


show : RelationStyle -> String
show order =
    case order of
        Bezier ->
            "Curve"

        Straight ->
            "Line"

        Steps ->
            "Steps"


toString : RelationStyle -> String
toString order =
    case order of
        Bezier ->
            "Bezier"

        Straight ->
            "Straight"

        Steps ->
            "Steps"


fromString : String -> RelationStyle
fromString order =
    case order of
        "Bezier" ->
            Bezier

        "Straight" ->
            Straight

        "Steps" ->
            Steps

        _ ->
            Bezier


encode : RelationStyle -> Value
encode value =
    value |> toString |> Encode.string


decode : Decode.Decoder RelationStyle
decode =
    Decode.string |> Decode.map fromString
