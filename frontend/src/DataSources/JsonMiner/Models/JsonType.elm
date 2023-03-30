module DataSources.JsonMiner.Models.JsonType exposing (JsonType, JsonTypeValue(..), decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode


type alias JsonType =
    { schema : String
    , name : String
    , value : JsonTypeValue
    }


type JsonTypeValue
    = JsonTypeEnum (List String)
    | JsonTypeDefinition String


decode : Decode.Decoder JsonType
decode =
    Decode.map3 JsonType
        (Decode.field "schema" Decode.string)
        (Decode.field "name" Decode.string)
        decodeValue


encode : JsonType -> Value
encode value =
    Encode.notNullObject
        ([ ( "schema", value.schema |> Encode.string )
         , ( "name", value.name |> Encode.string )
         ]
            ++ encodeValue value.value
        )


decodeValue : Decode.Decoder JsonTypeValue
decodeValue =
    Decode.oneOf
        [ Decode.field "values" (Decode.list Decode.string) |> Decode.map JsonTypeEnum
        , Decode.field "definition" Decode.string |> Decode.map JsonTypeDefinition
        ]


encodeValue : JsonTypeValue -> List ( String, Encode.Value )
encodeValue value =
    case value of
        JsonTypeEnum values ->
            [ ( "values", values |> Encode.list Encode.string ) ]

        JsonTypeDefinition definition ->
            [ ( "definition", definition |> Encode.string ) ]
