module Models.Project.ColumnDbStats exposing (ColumnDbStats, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.ColumnValue exposing (ColumnValue)


type alias ColumnDbStats =
    -- stats loaded from db computed stats
    { nulls : Maybe Float
    , bytesAvg : Maybe Float
    , cardinality : Maybe Float
    , commonValues : Maybe (List { value : ColumnValue, freq : Float })
    , histogram : Maybe (List ColumnValue)
    }


decode : Decoder ColumnDbStats
decode =
    Decode.map5 ColumnDbStats
        (Decode.maybeField "nulls" Decode.float)
        (Decode.maybeField "bytesAvg" Decode.float)
        (Decode.maybeField "cardinality" Decode.float)
        (Decode.maybeField "commonValues" (Decode.list decodeValue))
        (Decode.maybeField "histogram" (Decode.list Decode.string))


encode : ColumnDbStats -> Value
encode value =
    Encode.notNullObject
        [ ( "nulls", value.nulls |> Encode.maybe Encode.float )
        , ( "bytesAvg", value.bytesAvg |> Encode.maybe Encode.float )
        , ( "cardinality", value.cardinality |> Encode.maybe Encode.float )
        , ( "commonValues", value.commonValues |> Encode.maybe (Encode.list encodeValue) )
        , ( "histogram", value.histogram |> Encode.maybe (Encode.list Encode.string) )
        ]


decodeValue : Decoder { value : String, freq : Float }
decodeValue =
    Decode.map2 (\v f -> { value = v, freq = f })
        (Decode.field "value" Decode.string)
        (Decode.field "freq" Decode.float)


encodeValue : { value : String, freq : Float } -> Value
encodeValue value =
    Encode.notNullObject
        [ ( "value", value.value |> Encode.string )
        , ( "freq", value.freq |> Encode.float )
        ]
