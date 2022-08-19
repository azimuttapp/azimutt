module DataSources.JsonMiner.Models.JsonType exposing (JsonType, JsonTypeValue(..), decode)

import Json.Decode as Decode


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


decodeValue : Decode.Decoder JsonTypeValue
decodeValue =
    Decode.oneOf
        [ Decode.field "values" (Decode.list Decode.string) |> Decode.map JsonTypeEnum
        , Decode.field "definition" Decode.string |> Decode.map JsonTypeDefinition
        ]
