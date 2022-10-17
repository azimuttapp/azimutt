module DataSources.JsonMiner.Models.JsonRelation exposing (JsonColumnRef, JsonRelation, decode)

import Json.Decode as Decode


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


decodeJsonColumnRef : Decode.Decoder JsonColumnRef
decodeJsonColumnRef =
    Decode.map3 JsonColumnRef
        (Decode.field "schema" Decode.string)
        (Decode.field "table" Decode.string)
        (Decode.field "column" Decode.string)
