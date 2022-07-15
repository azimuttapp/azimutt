module DataSources.DatabaseSchemaParser.DatabaseSchema exposing (DatabaseSchema, decode)

import DataSources.DatabaseSchemaParser.Models.DatabaseRelation as DatabaseRelation exposing (DatabaseRelation)
import DataSources.DatabaseSchemaParser.Models.DatabaseTable as DatabaseTable exposing (DatabaseTable)
import Json.Decode as Decode


type alias DatabaseSchema =
    { tables : List DatabaseTable
    , relations : List DatabaseRelation
    }


decode : Decode.Decoder DatabaseSchema
decode =
    Decode.map2 DatabaseSchema
        (Decode.field "tables" (Decode.list DatabaseTable.decode))
        (Decode.field "relations" (Decode.list DatabaseRelation.decode))
