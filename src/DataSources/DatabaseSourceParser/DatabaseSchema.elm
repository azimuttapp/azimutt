module DataSources.DatabaseSourceParser.DatabaseSchema exposing (DatabaseSchema, decode, empty)

import DataSources.DatabaseSourceParser.Models.DatabaseRelation as DatabaseRelation exposing (DatabaseRelation)
import DataSources.DatabaseSourceParser.Models.DatabaseTable as DatabaseTable exposing (DatabaseTable)
import Json.Decode as Decode


type alias DatabaseSchema =
    { tables : List DatabaseTable
    , relations : List DatabaseRelation
    }


empty : DatabaseSchema
empty =
    { tables = [], relations = [] }


decode : Decode.Decoder DatabaseSchema
decode =
    Decode.map2 DatabaseSchema
        (Decode.field "tables" (Decode.list DatabaseTable.decode))
        (Decode.field "relations" (Decode.list DatabaseRelation.decode))
