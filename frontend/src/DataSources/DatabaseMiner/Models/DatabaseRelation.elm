module DataSources.DatabaseMiner.Models.DatabaseRelation exposing (ColumnLink, DatabaseRelation, DatabaseTableRef, decode)

import Json.Decode as Decode


type alias DatabaseRelation =
    { name : String
    , src : DatabaseTableRef
    , ref : DatabaseTableRef
    , columns : List ColumnLink
    }


type alias DatabaseTableRef =
    { schema : String, table : String }


type alias ColumnLink =
    { src : String, ref : String }


decode : Decode.Decoder DatabaseRelation
decode =
    Decode.map4 DatabaseRelation
        (Decode.field "name" Decode.string)
        (Decode.field "src" decodeDatabaseTableRef)
        (Decode.field "ref" decodeDatabaseTableRef)
        (Decode.field "columns" (Decode.list decodeColumnLink))


decodeDatabaseTableRef : Decode.Decoder DatabaseTableRef
decodeDatabaseTableRef =
    Decode.map2 DatabaseTableRef
        (Decode.field "schema" Decode.string)
        (Decode.field "table" Decode.string)


decodeColumnLink : Decode.Decoder ColumnLink
decodeColumnLink =
    Decode.map2 ColumnLink
        (Decode.field "src" Decode.string)
        (Decode.field "ref" Decode.string)
