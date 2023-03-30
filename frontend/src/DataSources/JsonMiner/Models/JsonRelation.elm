module DataSources.JsonMiner.Models.JsonRelation exposing (JsonColumnRef, JsonRelation, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode


type alias JsonRelation =
    { name : String
    , src : JsonColumnRef
    , ref : JsonColumnRef
    }


type alias JsonColumnRef =
    { schema : String
    , table : String
    , column : String
    }


decode : Decode.Decoder JsonRelation
decode =
    Decode.map3 JsonRelation
        (Decode.field "name" Decode.string)
        (Decode.field "src" decodeJsonColumnRef)
        (Decode.field "ref" decodeJsonColumnRef)


encode : JsonRelation -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.string )
        , ( "src", value.src |> encodeJsonColumnRef )
        , ( "ref", value.ref |> encodeJsonColumnRef )
        ]


decodeJsonColumnRef : Decode.Decoder JsonColumnRef
decodeJsonColumnRef =
    Decode.map3 JsonColumnRef
        (Decode.field "schema" Decode.string)
        (Decode.field "table" Decode.string)
        (Decode.field "column" Decode.string)


encodeJsonColumnRef : JsonColumnRef -> Value
encodeJsonColumnRef value =
    Encode.notNullObject
        [ ( "schema", value.schema |> Encode.string )
        , ( "table", value.table |> Encode.string )
        , ( "column", value.column |> Encode.string )
        ]
