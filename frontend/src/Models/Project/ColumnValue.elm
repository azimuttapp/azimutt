module Models.Project.ColumnValue exposing (ColumnValue, decode, decodeAny, encode, label, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Bool as Bool


type alias ColumnValue =
    String


label : ColumnValue -> String
label value =
    case value |> String.split "::" of
        val :: _ :: [] ->
            val

        _ ->
            value


merge : ColumnValue -> ColumnValue -> ColumnValue
merge v1 _ =
    v1


encode : ColumnValue -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnValue
decode =
    Decode.string


decodeAny : Decode.Decoder ColumnValue
decodeAny =
    Decode.oneOf
        [ Decode.string
        , Decode.null "null"
        , Decode.bool |> Decode.map Bool.toString
        , Decode.int |> Decode.map String.fromInt
        , Decode.float |> Decode.map String.fromFloat
        , Decode.value |> Decode.map (Encode.encode 0)
        ]
