module DataSources.DatabaseMiner.DatabaseSchema exposing (DatabaseSchema, decode, empty)

import DataSources.DatabaseMiner.Models.DatabaseRelation as DatabaseRelation exposing (DatabaseRelation)
import DataSources.DatabaseMiner.Models.DatabaseTable as DatabaseTable exposing (DatabaseTable)
import DataSources.DatabaseMiner.Models.DatabaseType as DatabaseType exposing (DatabaseType)
import Json.Decode as Decode


type alias DatabaseSchema =
    { tables : List DatabaseTable
    , relations : List DatabaseRelation
    , types : List DatabaseType
    }


empty : DatabaseSchema
empty =
    { tables = [], relations = [], types = [] }


decode : Decode.Decoder DatabaseSchema
decode =
    Decode.map3 DatabaseSchema
        (Decode.field "tables" (Decode.list DatabaseTable.decode))
        (Decode.field "relations" (Decode.list DatabaseRelation.decode))
        (Decode.field "types" (Decode.list DatabaseType.decode))
